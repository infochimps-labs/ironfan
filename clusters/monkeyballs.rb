ClusterChef.cluster 'monkeyballs' do
  use :defaults
  setup_role_implications
  mounts_ephemeral_volumes

  cloud do
    backing             "ebs"
    image_name          'infochimps-maverick-client'
    flavor "t1.micro"
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

  facet 'jobtracker' do
    instances           1
    role                "hadoop_jobtracker"
    role                "hadoop_secondarynamenode"
    cloud.flavor        "m1.xlarge"
  end

  facet 'worker' do
    instances           3
    role                "hadoop_worker"
    cloud.flavor        "m1.xlarge"

    volume(:data, :mount_options => 'defaults,nouuid,noatime', :fs_type => 'xfs') do
      snapshot_id   'snap-d9c1edb1'
      size          50
      device        '/dev/sdm'
      mount_point   '/data'
      keep          true
    end
    server 0 do
      volume(:data).volume_id()
      cloud.elastic_ip '184.73.203.79'
    end
    server 1 do
      volume(:data).volume_id('vol-c55903ae')
      cloud.elastic_ip '184.73.174.3'
    end
    server 2 do
      volume(:data).volume_id()
      cloud.elastic_ip '184.73.205.98'
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
