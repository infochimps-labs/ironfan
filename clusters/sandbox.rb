ClusterChef.cluster 'sandbox' do
  cloud :ec2 do
    defaults
    availability_zones ['us-east-1d']
    flavor              't1.micro'
    backing             'ebs'
    image_name          'infochimps-natty'
    bootstrap_distro    'ubuntu10.04-cluster_chef'
    chef_client_script  'client.rb'
    mount_ephemerals(:tags => { :hadoop_scratch => true })
  end

  environment           :dev

  role                  :base_role
  role                  :chef_client
  role                  :ssh
  role                  :nfs_client
  role                  :volumes

  role                  :infochimps_base

  facet :korny do
    instances           1
  end

  cluster_role.override_attributes({
      :apt => { :cloudera => {
          :force_distro      => 'maverick', # no natty distro  yet
          :release_name      => 'cdh3u2',
        }, },
      :hadoop                => {
        :hadoop_handle       => 'hadoop-0.20',
        :deb_version         => '0.20.2+923.142-1~maverick-cdh3',
        :persistent_dirs     => ['/mnt'],
        :scratch_dirs        => ['/mnt'],
        #
        :namenode      => { :run_state => :stop },
        :secondarynn   => { :run_state => :stop },
        :jobtracker    => { :run_state => :stop },
        :datanode      => { :run_state => :stop },
        :tasktracker   => { :run_state => :stop },
      },
      :volumes       => {
        :aws_credential_source => 'node_attributes',
      }
    })

end
