ClusterChef.cluster 'demosimple' do
  use :defaults
  mounts_ephemeral_volumes
  setup_role_implications

  cloud do
    backing             "ebs"
    image_name          "maverick"
    flavor              "t1.micro"
    availability_zones  ['us-east-1a']
    bootstrap_distro    "ubuntu10.10-cluster_chef"
  end

  cluster_role do
    run_list(*%w[
       role[chef_client]
    ])
  end

  facet :homebase do
    instances           1

    facet_role do
      run_list(*%w[
       role[nfs_server]
       role[big_package]
      ])
    end

  end

  chef_attributes({
      :webnode_count => facet(:webnode).instances,
    })
end
