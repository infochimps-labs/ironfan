# aws included via metadata.rb

cluster_ebs_volumes = data_bag_item('cluster_ebs_volumes', node[:cluster_name]) rescue nil
cluster_node_index  = node[:cluster_node_index] || node[:ec2][:ami_launch_index]

if cluster_ebs_volumes
  template "/tmp/ebs_settings.yaml" do
    owner "root"
    mode "0644"
    variables :cluster_ebs_volumes => cluster_ebs_volumes
    source "ebs_settings.yaml.erb"
  end

  vol_confs = cluster_ebs_volumes[cluster_role][cluster_node_index.to_i] rescue []
  vol_confs.each do |vol_conf|
    Chef::Log.info vol_conf.inspect
    aws_ebs_volume "attach hdfs volume #{conf.inspect}" do
      provider "aws_ebs_volume"
      aws_access_key        node[:aws][:aws_access_key]
      aws_secret_access_key node[:aws][:aws_secret_access_key]
      aws_region            node[:aws][:aws_region]
      availability_zone     node[:aws][:availability_zone]
      volume_id             vol_conf[:volume_id]
      device                vol_conf[:device]
      action :attach
    end
  end
end

