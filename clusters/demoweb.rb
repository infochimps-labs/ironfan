ClusterChef.cluster 'demoweb' do
  use :defaults
  mounts_ephemeral_volumes 

  #
  # Define some security group triggered on having certain roles
  #
  setup_role_implications
  # if you're a redis server, open the port and authorize redis clients in your group to talk to you
  role_implication("redis_server") do
    cluster_name = self.cluster_name # now cluster_name is in scope
    self.cloud.security_group("#{cluster_name}-redis_server") do
      authorize_group("#{cluster_name}-redis_client")
    end
  end
  role_implication("redis_client") do
    self.cloud.security_group("#{cluster_name}-redis_client")
  end
  # web server? add the group "demoweb-awesome_website" and open the web holes
  role_implication("awesome_website") do
    self.cloud.security_group("#{cluster_name}-awesome_website") do
      authorize_port_range 80..80
      authorize_port_range 443..443
    end
  end

  cloud do
    backing             "instance"
    image_name          "maverick"
    flavor              "t1.micro"
    availability_zones  ['us-east-1a']
  end
  
  role                  "nfs_client"
  role                  "big_package"

  facet :webnode do
    instances           6
    role                "nginx"
    role                "redis_client"
    role                "mysql_client"
    role                "elasticsearch_client"
    role                "awesome_website"
    #
    cloud.backing       "ebs"
    azs = ['us-east-1a', 'us-east-1b', 'us-east-1c']
    (0...instances).each do |idx|
      server(idx).cloud.availability_zones [azs[ idx % azs.length ]]
    end

    chef_attributes({ :split_testing => { :group => 'A' } })
    
    server(5) do
      chef_attributes({ :split_testing => { :group => 'B' } })
    end
  end

  facet :dbnode do
    instances           2
    role                "mysql_server"
    role                "redis_client"
    # an m1.large is usually OK but if we have to increase the number of backend
    # machines, make the extra machines large.
    cloud.flavor        "c1.xlarge"
    server(0) do
      cloud.flavor      "m1.large"
    end

    volume(:data) do
      size          50
      keep          true
      device        '/dev/sdi'
      mount_point   '/data/db'
      mount_options 'defaults,nouuid,noatime'
      fs_type       'xfs'      
    end
    server(0).volume(:data).snapshot_id 'snap-d9c1edb1'
    server(1).volume(:data) do
      snapshot_id 'snap-d9c1edb1'
      volume_id   'vol-12345'
    end    
  end

  facet :esnode do
    instances           1
    role                "nginx"
    role                "redis_server"
    role                "elasticsearch_data_esnode"
    role                "elasticsearch_http_esnode"
    #
    cloud.flavor        "m1.large"
  end


  chef_attributes({
      :webnode_count => facet(:webnode).instances,
    })
  
end
