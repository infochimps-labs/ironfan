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

  role                  "nfs_client"
  recipe                "package_set"

  facet :webnode do
    instances           6
    role                "nginx"
    role                "redis_client"
    role                "mysql_client"
    role                "elasticsearch_client"
    role                "awesome_website"
    role                "web_server"      # this triggers opening appropriate ports
    # Rotate nodes among availability zones
    azs = ['us-east-1d', 'us-east-1b', 'us-east-1c']
    (0...instances).each do |idx|
      server(idx).cloud.availability_zones [azs[ idx % azs.length ]]
    end
    # Rote nodes among A/B testing groups
    (0..instances).each do |idx|
      server(idx).chef_node.normal[:split_testing] = ( (idx % 2 == 0) ? 'A' : 'B' )
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
      fstype       'xfs'
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
