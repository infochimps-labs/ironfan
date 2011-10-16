ClusterChef::Cloud::Ec2::IMAGE_INFO.merge!({
        %w[us-east-1             64-bit  ebs             mrflip-natty       ] => { :image_id => 'ami-a979b5c0', :ssh_user => 'ubuntu', :bootstrap_distro => "ubuntu10.04-cluster_chef", }, #
  })
ClusterChef.cluster 'demosimple' do
  mounts_ephemeral_volumes
  setup_role_implications

  cloud :ec2 do
    availability_zones  ['us-east-1a']
    flavor              "t1.micro"
    backing             "ebs"
    image_name          "mrflip-natty"
    bootstrap_distro    "ubuntu10.04-cluster_chef"
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh

  cluster_role

  #
  # An NFS server to hold your home drives.
  #
  # It's stop-start'able, but if you're going to use this long-term, you should
  # consider creating a separate EBS volume to hold /home
  #
  facet :homebase do
    instances           1
    role                :nfs_server
    facet_role
  end

  #
  # A throwaway facet for testing
  #
  facet :sandbox do
    instances           2
    cloud do
      flavor           "m1.large"
      backing          "ebs"
    end
    role                :nfs_client

    volume(:data) do
      size              10
      keep              true
      device            '/dev/sdi' # note: will appear as /dev/xvdi on natty
      mount_point       '/data/db'
      mount_options     'defaults,nouuid,noatime'
      fs_type           'xfs'
      snapshot_id       'snap-a6e0bec5'
    end
    server(0).volume(:data) do
      volume_id         'vol-bd6d51d7'
    end
    server(1).volume(:data) do
      volume_id         'vol-b95d61d3'
    end

    facet_role do
      run_list(*%w[
        role[base_role]
        role[chef_client]
        role[ssh]
        role[nfs_client]
        java::sun
        jpackage

        role[hadoop]
        role[big_package]
        role[elasticsearch_client]
        boost
        git
        mysql
        mysql::client
        ntp
        openssl
        thrift
        xfs

        role[demosimple_cluster]
        role[demosimple_sandbox]
      ])

      override_attributes({
          :hadoop => {
            :hadoop_handle        => 'hadoop-0.20',
            :cdh_version          => 'cdh3u1',
            :deb_version          => "0.20.2+923.97-1~maverick-cdh3",
            :cloudera_distro_name => 'maverick', # in case cloudera doesn't have your distro yet
          },
          :elasticsearch => {
            :version              => '0.17.8',
          },
          :active_users => [ "flip"],
          :authorization => { :sudo => { :groups => ['admin'], :users => ['ubuntu'] } },
          :groups => {
            'deploy'        => { :gid => 2000, },
            #
            'admin'         => { :gid =>  200, },
            'sudo'          => { :gid =>  201, },
            #
            'hadoop'        => { :gid =>  300, },
            'supergroup'    => { :gid =>  301, },
            'hdfs'          => { :gid =>  302, },
            'mapred'        => { :gid =>  303, },
            'hbase'         => { :gid =>  304, },
            'zookeeper'     => { :gid =>  305, },
            #
            'cassandra'     => { :gid =>  330, },
            'databases'     => { :gid =>  331, },
            'azkaban'       => { :gid =>  332, },
            'redis'         => { :gid =>  335, },
            'memcached'     => { :gid =>  337, },
            'jenkins'       => { :gid =>  360, },
            'elasticsearch' => { :gid =>  61021, },
            #
            'webservers'    => { :gid =>  401, },
            'nginx'         => { :gid =>  402, },
            'scraper'       => { :gid =>  421, },
          },
        })

    end
  end
end
