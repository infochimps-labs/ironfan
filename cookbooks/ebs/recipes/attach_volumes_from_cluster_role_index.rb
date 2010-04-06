# aws included via metadata.rb

cluster_node_index  = (node[:cluster_node_index] || node[:ec2][:ami_launch_index]).to_i
all_cluster_volumes = data_bag_item('cluster_ebs_volumes', node[:cluster_name])    rescue nil
cluster_ebs_volumes = all_cluster_volumes[node[:cluster_role]][cluster_node_index] rescue nil
Chef::Log.info ["attach_volumes_from_cluster_role_index", node[:cluster_name], node[:cluster_role], cluster_node_index, cluster_ebs_volumes].inspect

if cluster_ebs_volumes
  template "/tmp/ebs_settings.yaml" do
    owner "root"
    mode "0644"
    variables :cluster_ebs_volumes => cluster_ebs_volumes
    source "ebs_settings.yaml.erb"
  end

  cluster_ebs_volumes.each do |conf|
    Chef::Log.info conf.inspect
    aws_ebs_volume "attach hdfs volume #{conf.inspect}" do
      provider "aws_ebs_volume"
      aws_access_key        node[:aws][:aws_access_key]
      aws_secret_access_key node[:aws][:aws_secret_access_key]
      aws_region            node[:aws][:aws_region]
      availability_zone     node[:aws][:availability_zone]
      volume_id             conf['volume_id']
      device                conf['device']
      action :attach
    end
  end
end
