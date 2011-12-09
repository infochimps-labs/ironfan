ClusterChef.cluster 'democassandra' do
  recipe                "tuning"
  role                  "ebs_volumes_attach"
  role                  "ebs_volumes_mount"
  role                  "hadoop_s3_keys"

  facet 'datanode' do
    instances           2
    cloud.flavor        "c1.medium"
    role                "nfs_client"
    role                "cassandra_datanode"
    recipe              "package_set"
    role                "hadoop_initial_bootstrap"
  end

end
