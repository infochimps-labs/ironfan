ClusterChef.cluster 'demosimple' do
  cloud(:ec2) do
    defaults
    availability_zones ['us-east-1d']
    image_name          'infochimps-natty'
    bootstrap_distro    'ubuntu10.04-cluster_chef'
    chef_client_script  'client.rb'
    mount_ephemerals
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh
  role                  :volumes

  #
  # An NFS server to hold your home drives.
  #
  # It's stop-start'able, but if you're going to use this long-term, you should
  # consider creating a separate EBS volume to hold /home
  #
  facet :homebase do
    instances           1
    role                :nfs_server

    recipe              'aws'
    recipe              'xfs'
    recipe              'ec2::attach_ebs'
    role                'mrflip_base'

    #
    # Follow the directions in the aws cookbook about an AWS credentials databag
    #
    # You will also need to format the volume -- something like `sudo mkfs.xfs -f /dev/xvdh`
    #
    volume(:home) do
      defaults
      size                15
      device              '/dev/sdh'       # note: will appear as /dev/xvdi on natty
      mount_point         '/home'
      attachable          :ebs
      # snapshot_id       ''               # create a snapshot and place its id here
      volume_id           'vol-cee531a3'
      create_at_launch    true             # if no volume is tagged for that node, it will be created
      tags                :home => '/home'
    end
  end

  #
  # A throwaway facet for development.
  #
  facet :sandbox do
    instances           1
    role                :nfs_client
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
      :volumes => {
        :aws_credential_source => 'node_attributes',
      }
    })

end
