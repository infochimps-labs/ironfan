ClusterChef.cluster 'monkeyballs' do
  use :defaults
  setup_role_implications
  mounts_ephemeral_volumes

  cloud do
    backing             "ebs"
    image_name          'infochimps-maverick-client'
    region              "us-east-1"
  end

  role                  "ebs_volumes_attach"
  role                  "nfs_client"
  recipe                "rvm"
  recipe                "rvm::gem_package"
  role                  "hadoop"
  role                  "hadoop_s3_keys"
  role                  "infochimps_base"
  role                  "big_package"
  role                  "ebs_volumes_mount"
  recipe                "cluster_chef::dedicated_server_tuning"

  facet 'namenode' do
    instances           1
    role                "hadoop_namenode"
    recipe              'hadoop_cluster::bootstrap_format_namenode'
    role                "hadoop_initial_bootstrap"
    cloud.flavor        "m1.xlarge"

    volume(:data, :mount_options => 'defaults,nouuid,noatime', :fs_type => 'xfs') do
      snapshot_id   'snap-d9c1edb1'
      size          50
      device        '/dev/sdh'
      mount_point   '/data'
      keep          true
    end
  end

  # facet 'jobtracker' do
  #   instances           1
  #   role                "hadoop_jobtracker"
  #   role                "hadoop_secondarynamenode"
  #   cloud.flavor        "m1.xlarge"
  # end

  facet 'worker' do
    instances           3
    role                "hadoop_worker"
    cloud.flavor        "m1.large"

    volume(:data, :mount_options => 'defaults,nouuid,noatime', :fs_type => 'xfs') do
      snapshot_id   'snap-d9c1edb1'
      size          50
      device        '/dev/sdh'
      mount_point   '/data'
      keep          false
    end
  end

  facet 'bootstrap' do
    instances           1
    recipe              "rvm"
    recipe              "rvm::gem_package"
    role                "big_package"
    recipe              'thrift'
    # cloud.flavor        "c1.xlarge"
    cloud.flavor        "t1.micro"
    # cloud.image_name    'maverick'
  end

end
