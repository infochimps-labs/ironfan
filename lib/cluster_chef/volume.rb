module ClusterChef
  #
  # Internal or external storage
  #
  class Volume < ClusterChef::DslObject
    attr_reader   :parent
    attr_accessor :fog_volume
    has_keys(
      :name,
      :volume_id, :snapshot_id, :size,
      :device, :mount_point, :mount_options, :fs_type,
      :availability_zone,
      :keep, :attachable, :create_at_launch
      )

    VOLUME_DEFAULTS = {
      :fs_type          => 'xfs',
      :mount_options    => 'defaults,nouuid,noatime',
      :attachable       => :ebs,
      :create_at_launch => false,
      :keep             => true,
    }

    #
    # ClusterChef::Volume.new(
    #   :device => '/dev/sdj', :mount_point => '/ebs1', :fs_type => 'xfs', :mount_options => 'defaults,nouuid,noatime'
    #   :size => 1024, :snapshot_id => 'snap-66494a08', :volume_id => 'vol-12312',
    #   :tags => {}, :keep => false )
    #
    def initialize attrs={}
      @parent = attrs.delete(:parent)
      super(attrs)
      @settings[:tags] ||= {}
    end

    def defaults
      self.configure(VOLUME_DEFAULTS)
    end

    def ephemeral_device?
      volume_id =~ /^ephemeral/
    end

    # With snapshot specified but volume missing, have it auto-created at launch
    def create_at_launch?
      self.create_at_launch
    end

    def in_cloud?
      !! fog_volume
    end

    def has_server?
      in_cloud? && fog_volume.server_id.present?
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
