module ClusterChef
  #
  # Internal or external storage
  #
  class Volume < ClusterChef::DslObject
    attr_reader   :parent
    attr_accessor :fog_volume
    has_keys(
      :name,
      # mountable volume attributes
      :device, :mount_point, :mount_options, :fstype, :mount_dump, :mount_pass,
      # cloud volume attributes
      :attachable, :create_at_launch, :volume_id, :snapshot_id, :size, :keep, :availability_zone,
      # arbitrary tags
      :tags
      )

    VOLUME_DEFAULTS = {
      :fstype          => 'xfs',
      :mount_options    => 'defaults,nouuid,noatime',
      :attachable       => :ebs,
      :create_at_launch => false,
      :keep             => true,
    }

    # Describes a volume
    #
    # @example
    #   ClusterChef::Volume.new( :name => 'redis',
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
        hsh.merge!({
            'Ebs.SnapshotId' => snapshot_id,
            'Ebs.VolumeSize' => size,
            'Ebs.DeleteOnTermination' => (! keep).to_s })
      else
        return
      end
      hsh
    end

  end
end
