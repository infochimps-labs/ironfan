ClusterChef.cluster 'goldencap' do
  use :defaults
  setup_role_implications

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
    instances           1
    cloud.flavor        "m1.small"
  end

  facet 'twscraper' do
    instances           4
    cloud.flavor        "m1.small"
  end

  facet 'nikko' do
    instances           1
    cloud.flavor        "m2.xlarge"
  end

  chef_attributes({
    })
end
