ClusterChef.cluster 'elasticsearch_demo' do
  mounts_ephemeral_volumes

  ec2 do
    availability_zones  ['us-east-1d']
    flavor              "t1.micro"
    backing             "ebs"
    image_name          "mrflip-natty"
    bootstrap_distro    "ubuntu10.04-cluster_chef"
  end

  role                  :base_role
  role                  :chef_client
  role                  :ssh
  role                  :nfs_client
  cluster_role
  recipe                "cluster_chef::dedicated_server_tuning"

  volume(:data) do
    size              10
    keep              true
    device            '/dev/sdi' # note: will appear as /dev/xvdi on natty
    mount_point       '/data/db'
    mount_options     'defaults,nouuid,noatime'
    fs_type           'xfs'
    snapshot_id       'snap-a6e0bec5'
  end

  facet :master do
    instances           1
    ec2 do
      flavor           "m1.large"
      backing          "ebs"
    end

    server(0).volume(:data){ volume_id('vol-bd6d51d7') }

    facet_role do
      run_list(*%w[
        role[base_role]
        role[chef_client]
        role[ssh]
        role[nfs_client]
        java::sun
        jpackage

        hadoop_cluster
        role[hadoop_namenode]
        role[hadoop_secondarynamenode]
        role[hadoop_datanode]
        role[hadoop_jobtracker]
        role[hadoop]
        hadoop_cluster::bootstrap_format_namenode
        hadoop_cluster::wait_on_hdfs_safemode
        hadoop_cluster::bootstrap_hdfs_dirs

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
          :service_states => {
            :hadoop_namenode           => [:enable],
            :hadoop_secondary_namenode => [:enable],
            :hadoop_jobtracker         => [:enable],
            :hadoop_datanode           => [:enable],
            :hadoop_tasktracker        => [:enable],
          },
          :active_users => [ "flip"],
        })
    end
  end

  facet :worker do
    instances           2
    ec2.flavor        "m1.large"
    #
    server(0).volume(:data){ volume_id('vol-b95d61d3') }
    #
    facet_role do
      run_list(*%w[
        role[chef_client]
        role[ssh]
        role[nfs_client]
        java::sun
        jpackage

        role[hadoop]
        role[hadoop_jobtracker]
        hadoop_cluster::bootstrap_format_namenode

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
          :service_states => {
            :hadoop_namenode           => [:disable, :stop],
            :hadoop_secondary_namenode => [:disable, :stop],
            :hadoop_jobtracker         => [:disable, :stop],
            :hadoop_datanode           => [:enable],
            :hadoop_tasktracker        => [:enable],
          },
          :active_users => [ "flip"],
        })
    end
  end

  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end
