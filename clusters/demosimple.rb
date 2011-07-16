ClusterChef.cluster 'demosimple' do
  use :defaults
  mounts_ephemeral_volumes
  setup_role_implications

  cloud do
    backing             "ebs"
    image_name          "maverick"
    flavor              "t1.micro"
    availability_zones  ['us-east-1a']
  end

  facet :homebase do
    instances           1
    role                "nfs_server"
    role                "big_package"
  end

  chef_attributes({
      :webnode_count => facet(:webnode).instances,
    })
end
