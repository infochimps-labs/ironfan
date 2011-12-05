ClusterChef.cluster 'demohbase' do
  use :defaults
  setup_role_implications

  recipe                "tuning"
  role                  "ebs_volumes_attach"
  role                  "ebs_volumes_mount"
  role                  "hadoop_s3_keys"
  cloud.flavor          "c1.medium"

  facet 'master' do
    instances           1
    facet_index         0
    role                "nfs_server"
    role                "hadoop_namenode"
    role                "hadoop_secondarynn"
    role                "hadoop_jobtracker"
    role                "hbase_master"
    role                "zookeeper_server"
    recipe              "package_set"
    role                "hadoop_initial_bootstrap"
  end

  facet 'regionserver' do
    instances           2
    role                "nfs_client"
    role                "hadoop_datanode"
    role                "hadoop_tasktracker"
    role                "hbase_regionserver"
  end

end
