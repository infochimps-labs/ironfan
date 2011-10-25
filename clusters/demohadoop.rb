ClusterChef.cluster 'demohadoop' do
  setup_role_implications
  mounts_ephemeral_volumes

  cloud do
    backing             "ebs"
    image_name          "maverick"
  end

  role                  "big_package"
  role                  "nfs_client"
  recipe                "cluster_chef::dedicated_server_tuning"

  facet :master do
    instances           1
    cloud.flavor        "m2.xlarge"
    #
    role                "hadoop"
    role                "hadoop_namenode"
    role                "hadoop_jobtracker"
    role                "hadoop_initial_bootstrap"
    role                "hadoop_tasktracker"
    role                "hadoop_datanode"
  end

  facet :worker do
    instances           2
    cloud.flavor        "m1.large"
    #
    role                "hadoop"
    role                "hadoop_namenode"
    role                "hadoop_jobtracker"
    role                "hadoop_initial_bootstrap"
    role                "hadoop_tasktracker"
    role                "hadoop_datanode"
    role                "hadoop_worker"
  end

  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end
