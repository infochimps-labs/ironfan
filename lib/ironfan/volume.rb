module Ironfan
  #
  # Internal or external storage
  #
  class Volume < Ironfan::DslObject
    attr_reader   :parent
    attr_accessor :fog_volume
    has_keys(
      :name,
      # mountable volume attributes
      :device, :mount_point, :mount_options, :fstype, :mount_dump, :mount_pass,
      :mountable, :formattable, :resizable, :in_raid,
      # cloud volume attributes
      :attachable, :create_at_launch, :volume_id, :snapshot_id, :size, :keep, :availability_zone,
      # arbitrary tags
      :tags
      )

    VOLUME_DEFAULTS = {
      :fstype          => 'xfs',
      :mount_options    => 'defaults,nouuid,noatime',
      :keep             => true,
      :attachable       => :ebs,
      :create_at_launch => false,
      #
      :mountable        => true,
      :resizable        => false,
      :formattable      => false,
      :in_raid          => false,
    }

    # Snapshot for snapshot_name method.
    # Set your own by adding
    #
    #     VOLUME_IDS = Mash.new unless defined?(VOLUME_IDS)
    #     VOLUME_IDS.merge!({ :your_id => 'snap-whatever' })
    #
    # to your organization's knife.rb
    #
    VOLUME_IDS = Mash.new unless defined?(VOLUME_IDS)
    VOLUME_IDS.merge!({
      :blank_xfs       => 'snap-d9c1edb1',
    })

    # Describes a volume
    #
    # @example
    #   Ironfan::Volume.new( :name => 'redis',
    #     :device => '/dev/sdp', :mount_point => '/data/redis', :fstype => 'xfs', :mount_options => 'defaults,nouuid,noatime'
    #     :size => 1024, :snapshot_id => 'snap-66494a08', :volume_id => 'vol-12312',
    #     :tags => {}, :keep => true )
    #
    def initialize attrs={}
      @parent = attrs.delete(:parent)
      super(attrs)
      @settings[:tags] ||= {}
    end

    # human-readable description for logging messages and such
    def desc
      "#{name} on #{parent.fullname} (#{volume_id} @ #{device})"
    end

    def defaults
      self.configure(VOLUME_DEFAULTS)
    end

    def ephemeral_device?
      volume_id =~ /^ephemeral/
    end

    # Named snapshots, as defined in Ironfan::Volume::VOLUME_IDS
    def snapshot_name(name)
      snap_id = VOLUME_IDS[name.to_sym]
      raise "Unknown snapshot name #{name} - is it defined in Ironfan::Volume::VOLUME_IDS?" unless snap_id
      self.snapshot_id(snap_id)
    end

    # With snapshot specified but volume missing, have it auto-created at launch
    #
    # Be careful with this -- you can end up with multiple volumes claiming to
    # be the same thing.
    #
    def create_at_launch?
      volume_id.blank? && self.create_at_launch
    end

    def in_cloud?
      !! fog_volume
    end

    def has_server?
      in_cloud? && fog_volume.server_id.present?
    end

    def reverse_merge!(other_hsh)
      super(other_hsh)
      self.tags.reverse_merge!(other_hsh.tags) if other_hsh.respond_to?(:tags) && other_hsh.tags.present?
      self
    end

    # An array of hashes with dorky-looking keys, just like Fog wants it.
    def block_device_mapping
      hsh = { 'DeviceName' => device }
      if ephemeral_device?
        hsh['VirtualName'] = volume_id
      elsif create_at_launch?
        raise "Must specify a size or a snapshot ID for #{self}" if snapshot_id.blank? && size.blank?
        hsh['Ebs.SnapshotId'] = snapshot_id if snapshot_id.present?
        hsh['Ebs.VolumeSize'] = size.to_s   if size.present?
        hsh['Ebs.DeleteOnTermination'] = (! keep).to_s
      else
        return
      end
      hsh
    end

  end


  #
  # Consider raising the chunk size to 256 and setting read_ahead 65536 if you are raid'ing EBS volumes
  #
  # * http://victortrac.com/EC2_Ephemeral_Disks_vs_EBS_Volumes
  # * http://orion.heroku.com/past/2009/7/29/io_performance_on_ebs/
  # * http://tech.blog.greplin.com/aws-best-practices-and-benchmarks
  # * http://stu.mp/2009/12/disk-io-and-throughput-benchmarks-on-amazons-ec2.html
  #
  class RaidGroup < Volume
    has_keys(
      :sub_volumes,     # volumes that comprise this raid group
      :level,           # RAID level (http://en.wikipedia.org/wiki/RAID#Standard_levels)
      :chunk,           # Raid chunk size (https://raid.wiki.kernel.org/articles/r/a/i/RAID_setup_cbb2.html)
      :read_ahead,      # read-ahead buffer
      )

    def desc
      "#{name} on #{parent.fullname} (#{volume_id} @ #{device} from #{sub_volumes.join(',')})"
    end

    def defaults()
      super
      fstype            'xfs'
      mount_options     "defaults,nobootwait,noatime,nouuid,comment=ironfan"
      attachable        false
      create_at_launch  false
      #
      mountable         true
      resizable         false
      formattable       true
      #
      in_raid           false
      #
      sub_volumes       []
    end
  end
end
