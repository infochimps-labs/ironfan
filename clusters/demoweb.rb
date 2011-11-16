ClusterChef.cluster 'demoweb' do
  cloud :ec2 do
    defaults
    availability_zones ['us-east-1d']
    flavor              't1.micro'  # change to something larger for serious use
    backing             'ebs'
    image_name          'natty'
    bootstrap_distro    'ubuntu10.04-cluster_chef'
    chef_client_script  'client.rb'
    mount_ephemerals(:tags => { :scratch_dirs => true })
  end

  # web server? add the group "demoweb-awesome_website" and open the web holes
  role_implication("awesome_website") do
    self.cloud.security_group("#{cluster_name}-awesome_website") do
      authorize_port_range 80..80
      authorize_port_range 443..443
    end
  end

  # if you're a redis server, open the port and authorize redis clients in your group to talk to you
  role_implication("redis_server") do
    cluster_name = self.cluster_name # now cluster_name is in scope
    self.cloud.security_group("#{cluster_name}-redis_server") do
      authorize_group("#{cluster_name}-redis_client")
    end
  end

  # if you're a redis server, open the port and authorize redis clients in your group to talk to you
  role_implication("redis_client") do
    self.cloud.security_group("#{cluster_name}-redis_client")
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
    azs = ['us-east-1d', 'us-east-1b', 'us-east-1c']
    (0...instances).each do |idx|
      server(idx).cloud.availability_zones [azs[ idx % azs.length ]]
    end

    (0..instances).each do |idx|
      chef_node.norma[:split_testing] = ( (idx % 2 == 0) ? 'A' : 'B' )
    end
  end

  facet :dbnode do
    instances           2
    role                "mysql_server"
    role                "redis_client"
    # burly master, wussier slaves
    cloud.flavor        "m1.large"
    server(0) do
      cloud.flavor      "c1.xlarge"
    end

    volume(:data) do
      size          50
      keep          true
      device        '/dev/sdi'
      mount_point   '/data/db'
      mount_options 'defaults,nouuid,noatime'
      fs_type       'xfs'
      snapshot_id   'snap-d9c1edb1'
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
end
