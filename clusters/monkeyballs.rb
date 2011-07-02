ClusterChef.cluster 'monkeyballs' do
  use :defaults
  setup_role_implications

  cloud do
    backing             "ebs"
    image_name          "maverick"
    region              "us-east-1"
  end

  role                  "ebs_volumes_attach"
  # role                  "nfs_client"
  # role                  "hadoop"
  # role                  "hadoop_s3_keys"
  # role                  "infochimps_base"
  role                  "ebs_volumes_mount"
  role                  "big_package"
  recipe                "cluster_chef::dedicated_server_tuning"
  
  facet 'namenode' do
    instances           1
    role                "hadoop_namenode"
    recipe              'hadoop_cluster::bootstrap_format_namenode'
    role                "hadoop_initial_bootstrap"
    cloud.flavor        "m1.xlarge"
  end

  facet 'jobtracker' do
    instances           1
    role                "hadoop_jobtracker"
    role                "hadoop_secondarynamenode"
    cloud.flavor        "m1.xlarge"
  end

  facet 'worker' do
    instances           1
    role                "hadoop_worker"
    cloud.flavor        "c1.xlarge"
  end

  facet 'bootstrap' do
    instances           1
    # %w[ rvm thrift whenever].each{|r| recipe r }
    cloud.flavor        "m1.large"
  end

  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end
