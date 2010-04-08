module ClusterEbsVolumes
  # ebs volume mapping for this node
  def cluster_ebs_volumes
    all_cluster_volumes[node[:cluster_role].to_s][node[:cluster_role_index].to_i] rescue []
  end

  # all ebs volumes for this cluster
  def all_cluster_volumes
    data_bag_item('cluster_ebs_volumes', node[:cluster_name]) rescue {}
  end

  def log_cluster_volume_info desc
    Chef::Log.info [
      desc,
      node[:cluster_name],       node[:cluster_role],
      node[:cluster_role_index], node[:ec2][:ami_launch_index],
      all_cluster_volumes, cluster_ebs_volumes,
    ].inspect
  end
end

class Chef::Recipe
  include ClusterEbsVolumes
end
class Chef::Resource::Directory
  include ClusterEbsVolumes
end

