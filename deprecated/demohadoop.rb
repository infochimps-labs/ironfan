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
  role                  :volumes
  role                  :hadoop
  role                  :hadoop_s3_keys
  role                  'pig'

  facet :master do
    instances           1
    role                :hadoop_namenode
    role                :hadoop_jobtracker
    role                :hadoop_secondarynn
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
      :apt => { :cloudera => {
          :force_distro => 'maverick', # no natty distro  yet
          :release_name => 'cdh3u2',
        }, },
      :hadoop => {
        :handle               => 'hadoop-0.20',
        :deb_version          => '0.20.2+923.142-1~maverick-cdh3',
        :persistent_dirs      => [], # will be auto-populated according to the volumes you attach
        :scratch_dirs         => ['/mnt/hadoop','/mnt2/hadoop','/mnt3/hadoop','/mnt4/hadoop'],
        # :java_heap_size_max            => 1400, # turn these up when you move to larger nodes
        # :namenode          => { :java_heap_size_max => 1000 },
        # :secondarynn => { :java_heap_size_max => 1000 },
        # :jobtracker        => { :java_heap_size_max => 3072 },
        :compress_mapout_codec      => 'org.apache.hadoop.io.compress.SnappyCodec',
      },
      :volumes => {
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
      :hadoop => {
        :namenode      => { :run_state => :stop },
        :secondarynn   => { :run_state => :stop },
        :jobtracker    => { :run_state => :stop },
        :datanode      => { :run_state => :stop },
        :tasktracker   => { :run_state => :stop },

        # :namenode    => { :run_state => :start, },
        # :secondarynn => { :run_state => :start, },
        # :jobtracker  => { :run_state => :start, },
        # :datanode    => { :run_state => :start, },
        # :tasktracker => { :run_state => :start, },
      },
    })

  facet(:worker).facet_role.override_attributes({
      :hadoop => {
        :datanode          => { :run_state => :start, },
        :tasktracker       => { :run_state => :start, },
      },
    })
end
