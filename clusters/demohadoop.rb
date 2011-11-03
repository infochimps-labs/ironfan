ClusterChef.cluster 'demohadoop' do
  cloud :ec2 do
    defaults
    availability_zones ['us-east-1d']
    flavor              't1.micro'
    backing             'ebs'
    image_name          'mrflip-natty'
    bootstrap_distro    'ubuntu10.04-cluster_chef'
    chef_client_script  'client-v3.rb'
    mount_ephemerals(:tags => { :hadoop_scratch => true })
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh
  role                  :nfs_client
  role                  :mountable_volumes

  role                  :mrflip_base

  facet :master do
    instances           1
    assign_volume_ids(:ebs1, [] )

    role                :hadoop
    role                :hadoop_s3_keys
    role                :hadoop_namenode
    # recipe              'hadoop_cluster::bootstrap_format_namenode'
    role                :hadoop_jobtracker
    role                :hadoop_secondarynamenode
    role                :hadoop_tasktracker
    role                :hadoop_datanode
    recipe              'hadoop_cluster::cluster_conf'
    role                :hadoop_initial_bootstrap
  end

  facet :worker do
    instances           6
    assign_volume_ids(:ebs1, [ ])

    role                :hadoop
    role                :hadoop_s3_keys
    role                :hadoop_tasktracker
    role                :hadoop_datanode
    recipe              'hadoop_cluster::cluster_conf'
  end

  volume(:ebs1) do
    defaults
    size                10
    device              '/dev/sdj' # note: will appear as /dev/xvdi on natty
    mount_point         '/data/ebs1'
    attachable          :ebs
    snapshot_id         'snap-a6e0bec5'
    tags( :hdfs => 'ebs1' )
  end

  cluster_role.override_attributes({
      :hadoop => {
        :hadoop_handle        => 'hadoop-0.20',
        :cdh_version          => 'cdh3u2',
        :deb_version          => '0.20.2+923.142-1~maverick-cdh3',
        :cloudera_distro_name => 'maverick', # no natty distro  yet
        :persistent_dirs      => [],
        :scratch_dirs         => ['/mnt/hadoop'],
      },
      :mountable_volumes => {
        :aws_credential_source => 'node_attributes',
      }
    })

  facet(:master).facet_role.override_attributes({
      :service_states => {
        :hadoop_namenode           => [:enable],
        :hadoop_secondarynamenode  => [:disable],
        :hadoop_jobtracker         => [:disable],
        :hadoop_datanode           => [:enable],
        :hadoop_tasktracker        => [:disable],
      },
    })

  facet(:worker).facet_role.override_attributes({
      :service_states => {
        :hadoop_datanode           => [:enable],
        :hadoop_tasktracker        => [:enable],
      },
    })
end
