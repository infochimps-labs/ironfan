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

  environment           :dev

  role                  :base_role,   :first
  role                  :chef_client, :first
  role                  :ssh,         :first

  role                  :mountable_volumes
  role                  :nfs_client
  role                  :hadoop_s3_keys, :first
  recipe                'cluster_chef'

  role                  :mrflip_base
  recipe                'big_package::default',         :last
  recipe                'cluster_chef::dashboard',      :last

  facet :grande do
    instances           1

    recipe              'ganglia::server'
    recipe              'ganglia::monitor'

    role                :flume_master
    role                :flume_node
    role                :zookeeper_server

    role                :redis_server
    role                :resque_server

    role                :hadoop,                        :first
    role                :hadoop_datanode
    role                :hadoop_jobtracker
    role                :hadoop_namenode
    role                :hadoop_secondarynn
    role                :hadoop_tasktracker
    recipe              'hadoop_cluster::cluster_conf', :last

    role                :hbase_master
    role                :hbase_regionserver

    role                :statsd_server

    # role                :graphite_server

    role                :pig
    recipe              'rstats'
    recipe              'nodejs'
    recipe              'jruby'
    recipe              'jruby::gems'

    role                :elasticsearch_data_esnode
    role                :elasticsearch_http_esnode
    role                :cassandra_datanode
  end

  facet :mucho do
    instances           1
    # role                :hadoop_tasktracker
    # role                :hadoop_datanode
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
        :secondarynn     => { :java_heap_size_max => 1000, },
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
  facet(:grande).facet_role.override_attributes({
      :ganglia => {
        :server              => { :service_state => :start },
        :monitor             => { :service_state => :start },
      },
      :hadoop => {
        :namenode            => { :service_state => :stop },
        :secondarynn   => { :service_state => :stop },
        :jobtracker          => { :service_state => :stop },
        :datanode            => { :service_state => :stop },
        :tasktracker         => { :service_state => :stop },
        #
        # :namenode          => { :service_state => :start, },
        # :secondarynn => { :service_state => :start, },
        # :jobtracker        => { :service_state => :start, },
        # :datanode          => { :service_state => :start, },
        # :tasktracker       => { :service_state => :start, },
      },
    })
end
