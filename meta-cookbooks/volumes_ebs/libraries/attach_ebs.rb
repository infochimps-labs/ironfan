module MountableVolumes


# Heavily inspired by [Robert Berger's HOWTO](http://blog.ibd.com/scalable-deployment/using-the-opscode-aws-cookbook-to-attach-an-ec2-ebs-volume/)

  # attachable volume mapping for this node -- selects any volume with an
  # :attachable value matching the given type
  #
  # @example
  #   # the first two will be returned when attachable_volumes(:ebs) is called.
  #   node[:volumes] = {
  #     :volumes => {
  #       :data  => { :name=>:data, :tags=>{}, :volume_id=>"vol-b95d61d3", :size=>10, :keep=>true, :device=>"/dev/sdi", :mount_point=>"/data", :snapshot_id=>"snap-a10234f", :attachable=>:ebs, :create_at_launch=>false, :availability_zone=>"us-east-1d"}
  #       :hdfs1 => { "device": "/dev/sdj",  "volume_id": "vol-cf0ed8a6", "mount_point": "/data/hdfs1", :attachable => :ebs },
  #       :hdfs2 => { "device": "/dev/sdk",  "volume_id": "vol-c10ed8a8", "mount_point": "/data/hdfs2", :attachable => :ebs },
  #       :mnt2  => { "device": "/dev/sdc",  "volume_id": "ephemeral1",   "mount_point": "/mnt2", },
  #     }
  #   }
  def attachable_volumes(type)
    return({}) unless volumes
    volumes.select{|vol_name, vol| vol['attachable'].to_s == type.to_s && (! vol['volume_id'].to_s.empty?) }
  end

  # Loads AWS credentials, from either databag or node metadata.
  # node metadata is supported, but is much less secure.
  #
  # @example
  #   # in your node definition
  #   default[:volumes][:aws_credential_source] = :node_attributes
  #   volumes_aws_credentials
  #   # { 'aws_access_key_id' => 'XXX', 'aws_secret_access_key' => 'XXX', ... }
  #
  def mntvol_aws_credentials
    if    node[:volumes][:aws_credential_source].to_s == 'data_bag'
      begin
        aws = data_bag_item("aws", node[:volumes][:aws_credential_handle])
      rescue Net::HTTPServerException => e
        Chef::Log.warn("Can't load data bag for AWS credentials #{node[:volumes][:aws_credential_handle]}: #{e}")
        return nil
      end
    elsif node[:volumes][:aws_credential_source].to_s == 'node_attributes'
      aws = node[:aws]
    end
    if aws.nil? || aws.empty? || aws['aws_access_key_id'].nil?
      Chef::Log.warn("You must set AWS permissions in your aws #{node[:volumes][:aws_credential_source]} for ebs::attach_volumes to work")
    else
      Chef::Log.info(aws.to_hash.inspect)
    end
    aws
  end
end
