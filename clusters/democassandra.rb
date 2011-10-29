ClusterChef.cluster 'democassandra' do
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

end
