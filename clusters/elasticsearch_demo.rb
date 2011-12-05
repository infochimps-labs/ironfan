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
  recipe                "tuning"

  volume(:data) do
    size              10
    keep              true
    device            '/dev/sdi' # note: will appear as /dev/xvdi on natty
    mount_point       '/data/db'
    mount_options     'defaults,nouuid,noatime'
    fstype           'xfs'
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
        role[hadoop_secondarynn]
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
          :apt => { :cloudera => {
              :force_distro => 'maverick', # no natty distro  yet
              :release_name => 'cdh3u2',
            }, },
          :hadoop => {
            :handle        => 'hadoop-0.20',
            :deb_version   => "0.20.2+923.97-1~maverick-cdh3",
          },
          :elasticsearch => {
            :version              => '0.17.8',
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
          :elasticsearch => {
            :version              => '0.17.8',
          },
          :active_users => [ "flip"],
        })
    end
  end

end
