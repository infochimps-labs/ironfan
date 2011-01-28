ClusterChef.cluster 'bonobo' do
  merge!('defaults')
  setup_role_implications

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "hadoop_s3_keys"
  cloud do
    flavor              "c1.xlarge"
    backing             "ebs"
    image_name          "maverick" # "infochimps-maverick-client"
    user_data           :get_name_from => 'broham'
  end

  facet 'master' do
    instances           1
    facet_index         0
    role                "nfs_server"
    role                "hadoop_master"
    recipe              'hadoop_cluster::bootstrap_format_namenode'
    role                "hadoop_worker"
    role                "hadoop_initial_bootstrap"
  end

  facet 'worker' do
    instances           2
    role                "nfs_client"
    role                "hadoop_worker"
  end

  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end
