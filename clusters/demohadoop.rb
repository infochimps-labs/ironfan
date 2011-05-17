# FIXME: delete_on_termination
# FIXME: disable_api_termination
# FIXME: block_device_mapping
# FIXME: instance_initiated_shutdown_behavior
# FIXME: elastic_ip's
#
# FIXME: should we autogenerate the "foo_cluster" and "foo_bar_facet" roles,
#        and dispatch those to the chef server?
# FIXME: EBS volumes?
ClusterChef.cluster 'demohadoop' do
  use :defaults
  setup_role_implications

  recipe                "cluster_chef::dedicated_server_tuning"
  role                  "hadoop_s3_keys"

  facet 'master' do
    instances           1
    facet_index         0
    role                "nfs_server"
    role                "hadoop_master"
    recipe              'hadoop_cluster::bootstrap_format_namenode'
    role                "hadoop_worker"
    role                "hadoop_initial_bootstrap"
    role                "big_package"
  end

  facet 'worker' do
    instances           2
    role                "nfs_client"
    role                "hadoop_worker"
    role                "big_package"
  end

  chef_attributes({
      :cluster_size => facet('worker').instances,
    })
end
