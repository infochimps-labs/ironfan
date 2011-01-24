# FIXME: delete_on_termination
# FIXME: disable_api_termination
# FIXME: block_device_mapping
# FIXME: instance_initiated_shutdown_behavior
# FIXME: elastic_ip's
#
# FIXME: should we autogenerate the "foo_cluster" and "foo_bar_facet" roles,
#        and dispatch those to the chef server?
# FIXME: EBS volumes?

ClusterChef.cluster 'demohadoop' do
  cloud :ec2 do
    region              'us-east-1'
    availability_zones  ['us-east-1d']
    flavor              'm1.small'
    image_name          'mrflip-maverick-client'
    backing             'ebs'
    permanent           false
    elastic_ip          false
    user_data           :get_name_from => 'broham'
    spot_price_fraction nil
    bootstrap_distro    'ubuntu10.04-cluster_chef'
  end

  role                  "base_role"
  role                  "chef_client"
  role                  "ssh"
  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "ebs_volumes_attach"
  role                  "ebs_volumes_mount"
  role                  "hadoop_s3_keys"

  facet 'master' do
    instances           1
    facet_index         0
    cloud.flavor        "c1.medium"
    role                "nfs_server"
    role                "hadoop_namenode"
    role                "hadoop_secondarynamenode"
    role                "hadoop_jobtracker"
    role                "hadoop_datanode"
    role                "hadoop_tasktracker"
    role                "big_package"
    role                "hadoop_initial_bootstrap"
  end

  facet 'worker' do
    instances           4
    cloud.flavor        "c1.medium"
    role                "nfs_client"
    role                "hadoop_datanode"
    role                "hadoop_tasktracker"
  end

  facet 'regionserver' do
    instances           2
    role                "nfs_client"
    role                "hadoop_datanode"
    role                "hadoop_tasktracker"
    role                "hbase_regionserver"
  end

  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end

ClusterChef.cluster 'democassandra' do
  cloud :ec2 do
    region              'us-east-1'
    availability_zones  ['us-east-1d']
    flavor              'm1.small'
    image_name          'mrflip-maverick-client'
    backing             'ebs'
    permanent           false
    elastic_ip          false
    user_data           :get_name_from => 'broham'
    spot_price_fraction nil
    bootstrap_distro    'ubuntu10.04-cluster_chef'
  end

  role                  "base_role"
  role                  "chef_client"
  role                  "ssh"
  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "ebs_volumes_attach"
  role                  "ebs_volumes_mount"
  role                  "hadoop_s3_keys"

  facet 'datanode' do
    instances           3
    cloud.flavor        "m1.large"
    role                "nfs_client"
    role                "cassandra_datanode"
    role                "big_package"
    role                "hadoop_initial_bootstrap"
  end
end
