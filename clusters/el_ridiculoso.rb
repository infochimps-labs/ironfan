ClusterChef.cluster 'el_ridiculoso' do
  cloud :ec2 do
    defaults
    availability_zones ['us-east-1d']
    flavor              'c1.xlarge'
    backing             'ebs'
    image_name          'infochimps-natty'
    bootstrap_distro    'ubuntu10.04-cluster_chef'
    chef_client_script  'client.rb'
    mount_ephemerals(:tags => { :hadoop_scratch => true })
  end

  environment           :prod

  role                  :base_role
  role                  :chef_client
  role                  :ssh

  role                  :mountable_volumes
  role                  :mrflip_base
  role                  :nfs_client
  recipe                :cluster_chef
  recipe                'big_package::default'

  role                  :hadoop_s3_keys

  facet :grande do
    instances           1

    # recipe              'rstats'
    recipe              'cluster_chef::dashboard'

    role                :elasticsearch_data_esnode
    role                :elasticsearch_http_esnode

    # role              :cassandra_datanode
    # role              :statsd_server
    # role              :jenkins_master
    # recipe            'ganglia::server'
    # role              :graphite_server
    # role              :flume_master
    # role              :hadoop
    # role              :hadoop_datanode
    # role              :hadoop_jobtracker
    # role              :hadoop_namenode
    # role              :hadoop_secondarynamenode
    # role              :hadoop_tasktracker
    # role              :hbase_master
    # recipe            'hadoop_cluster::cluster_conf'
    # role              :redis_server
    # role              :resque_server
    # role              :zookeeper_server
    # role              :pig
    # recipe            'nodejs'
    # recipe            'jruby'
    # recipe            'jruby::gems'
  end

  facet :mucho do
    instances           1
    # role                :hadoop_tasktracker
    # role                :hadoop_datanode
    # role                :jenkins_node
    # recipe              'hadoop_cluster::cluster_conf'
  end

  cluster_role.override_attributes({
      :apt => { :cloudera => {
          :force_distro => 'maverick', # no natty distro  yet
          :release_name => 'cdh3u2',
        }, },
      :hadoop => {
        :hadoop_handle         => 'hadoop-0.20',
        :deb_version           => '0.20.2+923.142-1~maverick-cdh3',
        :persistent_dirs       => ['/mnt/hadoop','/mnt2/hadoop','/mnt3/hadoop','/mnt4/hadoop'],
        :scratch_dirs          => ['/mnt/hadoop','/mnt2/hadoop','/mnt3/hadoop','/mnt4/hadoop'],
        :java_heap_size_max    => 1400,
        :namenode              => { :java_heap_size_max => 1000, },
        :secondarynamenode     => { :java_heap_size_max => 1000, },
        :jobtracker            => { :java_heap_size_max => 3072, },
        :compress_mapout_codec => 'org.apache.hadoop.io.compress.SnappyCodec',
      },
      :mountable_volumes => {
        :aws_credential_source => 'node_attributes',
      }
    })

  #
  # After initial bootstrap, comment out the first set of lines (which stop all
  # the services that want a namenod to connect to) and uncomment the ones that
  # follow. Then run `knife cluster sync gibbon-master` followed by `knife
  # cluster kick gibbon-master` to re-converge.
  #
  # As soon as you see 'nodes=1' on the jobtracker (host:50030) and
  # namenode (host:50070) control panels, you're good to launch the rest
  # of the cluster (`knife cluster launch gibbon`)
  #
  facet(:master).facet_role.override_attributes({
      :hadoop => {
        :namenode            => { :service_state => [:disable, :stop] },
        :secondarynamenode   => { :service_state => [:disable, :stop] },
        :jobtracker          => { :service_state => [:disable, :stop] },
        :datanode            => { :service_state => [:disable, :stop] },
        :tasktracker         => { :service_state => [:disable, :stop] },
        #
        # :namenode          => { :service_state => [:enable, :start], },
        # :secondarynamenode => { :service_state => [:enable, :start], },
        # :jobtracker        => { :service_state => [:enable, :start], },
        # :datanode          => { :service_state => [:enable, :start], },
        # :tasktracker       => { :service_state => [:enable, :start], },
        :namenode_service_state => [:disable, :stop],
      },
    })

  facet(:worker).facet_role.override_attributes({
      :hadoop => {
        :datanode          => { :service_state => [:enable, :start], },
        :tasktracker       => { :service_state => [:enable, :start], },
      },
    })
end
