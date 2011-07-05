module ClusterChef
  #
  # Internal or external storage
  #
  class Volume < ClusterChef::DslObject
    attr_reader :parent
    has_keys(
      :keep, :name,
      :volume_id, :snapshot_id, :size,
      :device, :mount_point, :mount_options, :fs_type,
      :availability_zone
      )

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

    def ephemeral_device?
      volume_id =~ /^ephemeral/
    end

    # An array of hashes with dorky-looking keys, just like Fog wants it.
    def block_device_mapping
      hsh = { 'DeviceName' => device }
      if ephemeral_device?
        hsh['VirtualName'] = volume_id
      else
        hsh.merge!({
            'Ebs.SnapshotId' => snapshot_id,
            'Ebs.VolumeSize' => size,
            'Ebs.DeleteOnTermination' => (! keep).to_s })
      end
      hsh
    end

  end
end
