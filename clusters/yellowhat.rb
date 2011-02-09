ClusterChef.cluster 'bonobo' do
  merge!('defaults')
  setup_role_implications

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "nfs_client"
  cloud do
    backing             "ebs"
    image_name          "maverick"
    user_data           :get_name_from => 'broham'
  end

  facet 'data_esnode' do
    instances           1
    cloud.flavor        'm1.small'
    role                'vanity_redis'
    role                'elasticsearch_data_esnode'
    role                'vanity_redis'
    role                'george'
  end

  facet 'webnode' do
    instances           2
    cloud.flavor        't1.micro'
  end

  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end
