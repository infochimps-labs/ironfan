ClusterChef.cluster 'chimpmark' do
  use :defaults
  setup_role_implications
  cluster_role

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "nfs_client"
  role                  "infochimps_base"
  role                  "big_package"
  role                  "hadoop"
  role                  "hadoop_worker"

  recipe                "hadoop_cluster::std_hdfs_dirs"


  cloud do
    backing             "instance"
    image_name          "infochimps-maverick-client"
    region              "us-east-1"
  end

  facet 'master' do
    facet_role
    instances           1
    cloud.flavor        "m1.xlarge"
  end

  facet 'slave' do
    facet_role
    instances           15
    cloud.flavor        "m1.xlarge"
  end

end
