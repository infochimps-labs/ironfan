ClusterChef.cluster 'yellowhat_staging' do
  use :defaults
  setup_role_implications

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "ebs_volumes_attach"
  role                  "nfs_client"
  role                  "infochimps_base"
  role                  "ebs_volumes_mount"
  role                  "benchmarkable"
  cloud do
    backing             "ebs"
    image_name          "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
  end

  facet 'webnode' do
    instances           1
    cloud.flavor        "m1.small"
    role                "redis_client"
    role                "mysql_client"
    role                "nginx"
    role                "elasticsearch_data_esnode"
    role                "elasticsearch_http_esnode"
    role                "elasticsearch_client"
    role                "george"
    role                "big_package"
  end

end
