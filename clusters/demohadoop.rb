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
  merge!('defaults')
  setup_role_implications

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
    instances           2
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
  merge!('defaults')
  setup_role_implications

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "ebs_volumes_attach"
  role                  "ebs_volumes_mount"
  role                  "hadoop_s3_keys"

  facet 'datanode' do
    instances           2
    cloud.flavor        "c1.medium"
    role                "nfs_client"
    role                "cassandra_datanode"
    role                "big_package"
    role                "hadoop_initial_bootstrap"
  end

  chef_attributes({
      :cluster_size => facet('datanode').instances,
    })
end
