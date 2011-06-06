ClusterChef.cluster 'goldencap' do
  use :defaults
  setup_role_implications

  recipe                "hadoop_cluster::system_internals"
  role                  "attaches_ebs_volumes"
  role                  "nfs_client"
  role                  "infochimps_base"
  role                  "mounts_ebs_volumes"
  role                  "benchmarkable"
  role                  "big_package"

  cloud do
    backing             "ebs"
    image_name          "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
    region "us-east"
  end

  facet 'twstream' do
    instances           1
    cloud.flavor        "m1.small"
  end

  facet 'twscraper' do
    instances           2
    cloud.flavor        "m1.small"
  end

  facet 'nikko' do
    instances           1
    cloud.flavor        "m2.xlarge"
  end

  chef_attributes({
    })
end
