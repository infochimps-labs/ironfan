ClusterChef.cluster 'demohadoop' do
  cloud :ec2 do
    defaults
    availability_zones ['us-east-1d']
    flavor              't1.micro'  # change to something larger for serious use
    backing             'ebs'
    image_name          'natty'
    bootstrap_distro    'ubuntu10.04-cluster_chef'
    chef_client_script  'client.rb'
    mount_ephemerals(:tags => { :scratch_dirs => true, :hadoop_scratch => true })
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh
  role                  :nfs_client
  role                  :mountable_volumes
  role                  :hadoop
  role                  :hadoop_s3_keys
  role                  'pig'

  facet :master do
    instances           1
    role                :hadoop_namenode
    role                :hadoop_jobtracker
    role                :hadoop_secondarynamenode
    role                :hadoop_tasktracker
    role                :hadoop_datanode
    recipe              'hadoop_cluster::cluster_conf'
  end

  facet :worker do
    instances           6
    role                :hadoop_tasktracker
    role                :hadoop_datanode
    recipe              'hadoop_cluster::cluster_conf'
  end

  volume(:ebs1) do
    defaults
    size                10              # increase size for serious use
    device              '/dev/sdj'      # note: will appear as /dev/xvdi on natty
    mount_point         '/data/ebs1'
    attachable          :ebs
    snapshot_id         'snap-a6e0bec5' # fix this to something correct for your infrastructure
    tags( :hdfs => 'ebs1' )
    create_at_launch    true            # if no volume is tagged for that node, it will be created
  end

  cluster_role.override_attributes({
      :hadoop => {
        :hadoop_handle        => 'hadoop-0.20',
        :cdh_version          => 'cdh3u2',
        :deb_version          => '0.20.2+923.142-1~maverick-cdh3',
        :cloudera_distro_name => 'maverick', # no natty distro  yet
        :persistent_dirs      => [], # will be auto-populated according to the volumes you attach
        :scratch_dirs         => ['/mnt/hadoop','/mnt2/hadoop','/mnt3/hadoop','/mnt4/hadoop'],
        # :daemon_heapsize            => 1400, # turn these up when you move to larger nodes
        # :namenode_heapsize          => 1000,
        # :secondarynamenode_heapsize => 1000,
        # :jobtracker_heapsize        => 3072,
        :compress_mapout_codec      => 'org.apache.hadoop.io.compress.SnappyCodec',
      },
      :mountable_volumes => {
        :aws_credential_source => 'node_attributes',
      }
    })

  #
  # After initial bootstrap, remove the first set of lines (which stop all the
  # services that want a namenod to connect to) and uncomment the ones that
  # follow. Then run `knife cluster sync demohadoop-master` followed by `knife
  # cluster kick demohadoop-master` to re-converge.
  #
  # As soon as you see 'nodes=1' on the jobtracker (host:50030) and namenode
  # (host:50070) control panels, you're good to launch the rest of the cluster
  # (`knife cluster launch demohadoop`)
  #
  facet(:master).facet_role.override_attributes({
      :service_states => {
        :hadoop_namenode           => [:disable, :stop],
        :hadoop_secondarynamenode  => [:disable, :stop],
        :hadoop_jobtracker         => [:disable, :stop],
        :hadoop_datanode           => [:disable, :stop],
        :hadoop_tasktracker        => [:disable, :stop],
        #
        # :hadoop_namenode           => [:enable, :start],
        # :hadoop_secondarynamenode  => [:enable, :start],
        # :hadoop_jobtracker         => [:enable, :start],
        # :hadoop_datanode           => [:enable, :start],
        # :hadoop_tasktracker        => [:enable, :start],
      },
    })

  facet(:worker).facet_role.override_attributes({
      :service_states => {
        :hadoop_datanode           => [:enable, :start],
        :hadoop_tasktracker        => [:enable, :start],
      },
    })
end
