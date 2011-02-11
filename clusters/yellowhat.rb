ClusterChef.cluster 'bonobo' do
  merge!('defaults')
  setup_role_implications

  recipe                "hadoop_cluster::system_internals"
  role                  "attaches_ebs_volumes"
  role                  "nfs_client"
  role                  "infochimps_base"
  role                  "mounts_ebs_volumes"
  cloud do
    backing             "ebs"
    image_name          "maverick"
    user_data           :get_name_from => 'broham'
  end

  facet 'esnode' do
    instances           1
    cloud.flavor        "m1.small"
    role                "redis_server"
    role                "elasticsearch_data_esnode"
    role                "big_package"
  end

  facet 'webnode' do
    instances           2
    cloud.flavor        "t1.micro"
    role                "redis_client"
    role                "elasticsearch_client"
    role                "george"
    role                "big_package"
  end

  chef_attributes({
    })
end
