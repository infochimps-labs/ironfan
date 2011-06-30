ClusterChef.cluster 'monkeyballs' do
  use :defaults
  setup_role_implications

  cloud do
    backing             "instance"
    image_name          "infochimps-maverick-client"
    region              "us-east-1"
  end

  role                  "nfs_client"
  role                  "hadoop"
  role                  "hadoop_s3_keys"
  role                  "infochimps_base"

  facet 'master' do
    instances           1
    role                "hadoop_master"
    recipe              'hadoop_cluster::bootstrap_format_namenode'
    role                "hadoop_initial_bootstrap"
    cloud.flavor        "m2.xlarge"
  end

  facet 'worker' do
    instances           2
    role                "hadoop_worker"
    cloud.flavor        "m2.xlarge"
  end

  role                  "big_package"
  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end
