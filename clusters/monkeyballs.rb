ClusterChef.cluster 'monkeyballs' do
  use :defaults
  setup_role_implications

  cloud do
    backing             "ebs"
    image_name          "maverick"
    region              "us-east-1"
  end

  role                  "nfs_client"
  role                  "hadoop"
  role                  "hadoop_s3_keys"
  role                  "infochimps_base"

  facet 'namenode' do
    instances           1
    role                "hadoop_namenode"
    recipe              'hadoop_cluster::bootstrap_format_namenode'
    role                "hadoop_initial_bootstrap"
    cloud.flavor        "m2.xlarge"
  end

  facet 'jobtracker' do
    instances           1
    role                "hadoop_jobtracker"
    role                "hadoop_secondarynamenode"
    cloud.flavor        "m2.xlarge"
  end

  facet 'worker' do
    instances           3
    role                "hadoop_worker"
    cloud.flavor        "m2.xlarge"
  end

  role                  "big_package"
  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end
