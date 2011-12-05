module MountableVolumes

  # mountable volume mapping for this node
  #
  # @example
  #   # all three listed volumes will be mounted.
  #   node[:volumes] = {
  #     :root     => {                         :mount_point => "/",     :scratch => true, },
  #     :scratch1 => { :device => "/dev/sdb",  :mount_point => "/mnt",  :scratch => true, },
  #     :scratch2 => { :device => "/dev/sdc",  :mount_point => "/mnt2", :scratch => true, },
  #     :hdfs1    => { :device => "/dev/sdj",  :mount_point => "/data/hdfs1", :persistent => true, :attachable => :ebs },
  #     :hdfs2    => { :device => "/dev/sdk",  :mount_point => "/data/hdfs2", :persistent => true, :attachable => :ebs },
  #     }
  def volumes
    vols = node[:volumes].to_hash || {}
    fix_for_xen!(vols)
    vols
  end

  def mounted_volumes
    volumes.select{|vol_name, vol| vol['device'] && File.exists?(vol['device']) }
  end

  #
  # Try each tag in order to find thus-tagged volumes.
  # The first set to have a match is returned.
  #
  def volumes_tagged(*tags)
    vols = volumes
    tags.each do |tag|
      result = vols.select{|vol_name, vol| vol['tags'] && vol['tags'][tag] }
      return result unless result.empty?
    end
    vols
  end

  # Use `file -s` to identify volume type: ohai doesn't seem to want to do so.
  def volume_fstype(vol)
    return vol['fstype'] if vol['fstype']
    return 'ext3' unless File.exists?(vol['device'])
    dev_type_str = `file -s '#{vol['device']}'`.chomp
    case
    when dev_type_str =~ /SGI XFS/           then 'xfs'
    when dev_type_str =~ /Linux.*(ext[2-4])/ then $1
    else
      raise "Can't determine filesystem type of #{vol['device']} -- set it explicitly in node[:volumes]"
    end
  end

  # On Xen virtualization systems (eg EC2), the volumes are *renamed* from
  # /dev/sdj to /dev/xvdj -- but the amazon API requires you refer to it as
  # /dev/sdj.
  #
  # If the virtualization is 'xen' **and** there are no /dev/sdXX devices
  # **and** there are /dev/xvdXX devices, we relabel all the /dev/sdXX device
  # points to be /dev/xvdXX.
  def fix_for_xen!(vols)
    return unless node[:virtualization] && (node[:virtualization][:system] == 'xen')
    return unless (Dir['/dev/sd*'].empty?) && (not Dir['/dev/xvd*'].empty?)
    vols.each do |vol_name, vol|
      next unless vol.has_key?('device')
      vol['device'].gsub!(%r{^/dev/sd}, '/dev/xvd')
    end
  end

end

class Chef::Recipe              ; include MountableVolumes ; end
class Chef::Resource::Directory ; include MountableVolumes ; end
class Chef::Resource            ; include MountableVolumes ; end
