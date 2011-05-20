
ClusterChef.cluster 'democassandra' do
  use :defaults
  setup_role_implications

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "ebs_volumes_attach"
  role                  "ebs_volumes_mount"
  role                  "hadoop_s3_keys"

  facet 'datanode' do
    instances           2
    cloud.flavor        "c1.medium"
    role                "nfs_client"
    role                "cassandra_datanode"
    role                "big_package"
    role                "hadoop_initial_bootstrap"
  end

  chef_attributes({
      :cluster_size => facet('datanode').instances,
    })
end
