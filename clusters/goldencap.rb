ClusterChef.cluster 'goldencap' do
  use :defaults
  setup_role_implications
  cluster_role

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "ebs_volumes_attach"
  role                  "nfs_client"
  role                  "infochimps_base"
  role                  "ebs_volumes_mount"
  role                  "benchmarkable"
  role                  "big_package"

  cloud do
    backing             "ebs"
    image_name          "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
    region "us-east-1"
  end

  facet 'twstream' do
    facet_role
    instances           1
    cloud.flavor        "m1.small"
  end

  facet 'twscraper' do
    facet_role
    instances           4
    cloud.flavor        "m1.small"
  end

  facet 'nikko' do
    facet_role
    instances           1
    cloud.flavor        "m2.xlarge"
  end

end
