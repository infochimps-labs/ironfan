module ClusterEbsVolumes

  # mountable volume mapping for this node
  #
  # @example
  #   # all three listed volumes will be mounted.
  #   node[:mountable_volumes] = {
  #     :volumes => {
  #       :hdfs1 => { "device": "/dev/sdj",  "volume_id": "vol-cf0ed8a6", "mount_point": "/data/hdfs1", :attachable => :ebs },
  #       :hdfs2 => { "device": "/dev/sdk",  "volume_id": "vol-c10ed8a8", "mount_point": "/data/hdfs2", :attachable => :ebs },
  #       :mnt2  => { "device": "/dev/sdc",  "volume_id": "ephemeral1",   "mount_point": "/mnt2", },
  #     }
  #   }
  def mountable_volumes
    vols = node[:mountable_volumes][:volumes].to_hash || {}
    vols.reject!{|vol_name, vol| vol['mount_point'].to_s.empty? || (vol['mountable'].to_s == 'false') }
    fix_for_xen!(vols)
    # Chef::Log.info( JSON.pretty_generate(vols) )
    vols
  end

  # attachable volume mapping for this node -- selects any volume with an
  # :attachable value matching the given type
  #
  # @example
  #   # the first two will be returned when attachable_volumes(:ebs) is called.
  #   node[:mountable_volumes] = {
  #     :volumes => {
  #       :data  => { :name=>:data, :tags=>{}, :volume_id=>"vol-b95d61d3", :size=>10, :keep=>true, :device=>"/dev/sdi", :mount_point=>"/data", :snapshot_id=>"snap-a10234f", :attachable=>:ebs, :create_at_launch=>false, :availability_zone=>"us-east-1a"}
  #       :hdfs1 => { "device": "/dev/sdj",  "volume_id": "vol-cf0ed8a6", "mount_point": "/data/hdfs1", :attachable => :ebs },
  #       :hdfs2 => { "device": "/dev/sdk",  "volume_id": "vol-c10ed8a8", "mount_point": "/data/hdfs2", :attachable => :ebs },
  #       :mnt2  => { "device": "/dev/sdc",  "volume_id": "ephemeral1",   "mount_point": "/mnt2", },
  #     }
  #   }
  def attachable_volumes(type)
    return({}) unless mountable_volumes
    mountable_volumes.select{|vol_name, vol| vol['attachable'].to_s == type.to_s && (! vol['volume_id'].to_s.empty?) }
  end

  def mounted_volumes
    mountable_volumes.select{|vol_name, vol| File.exists?(vol['device']) }
  end

  def mounted_volumes_tagged(tag)
    mounted_volumes.select{|vol_name, vol| vol['tags'] && vol['tags'][tag] }
  end

  # Loads AWS credentials, from either databag or node metadata.
  # node metadata is supported, but is much less secure.
  #
  # @example
  #   # in your node definition
  #   default[:mountable_volumes][:aws_credential_source] = :node_attributes
  #   mountable_volumes_aws_credentials
  #   # { 'aws_access_key_id' => 'XXX', 'aws_secret_access_key' => 'XXX', ... }
  #
  def mntvol_aws_credentials
    if    node[:mountable_volumes][:aws_credential_source].to_s == 'data_bag'
      begin
        aws = data_bag_item("aws", node[:mountable_volumes][:aws_credential_handle])
      rescue Net::HTTPServerException => e
        Chef::Log.warn("Can't load data bag for AWS credentials #{node[:mountable_volumes][:aws_credential_handle]}: #{e}")
        return nil
      end
    elsif node[:mountable_volumes][:aws_credential_source].to_s == 'node_attributes'
      aws = node[:aws]
    end
    if aws.nil? || aws.empty? || aws['aws_access_key_id'].nil?
      Chef::Log.warn("You must set AWS permissions in your aws #{node[:mountable_volumes][:aws_credential_source]} for ebs::attach_volumes to work")
    end
    aws
  end

  # Use `file -s` to identify volume type: ohai doesn't seem to want to do so.
  def fstype_from_file_magic(dev)
    return 'ext3' unless File.exists?(dev)
    dev_type_str = `file -s '#{dev}'`
    case
    when dev_type_str =~ /SGI XFS/           then 'xfs'
    when dev_type_str =~ /Linux.*ext3/       then 'ext3'
    else
      Chef::Log.info("Can't determine filesystem type of #{dev} -- consider setting it explicitly in node[:mountable_volumes]")
      'ext3'
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

class Chef::Recipe              ; include ClusterEbsVolumes ; end
class Chef::Resource::Directory ; include ClusterEbsVolumes ; end
class Chef::Resource            ; include ClusterEbsVolumes ; end
