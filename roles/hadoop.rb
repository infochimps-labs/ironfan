name        'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  hadoop_cluster
  hadoop_cluster::cluster_conf
  hadoop_cluster::ec2_conf
  cluster_chef::dedicated_server_tuning
  pig::install_from_package
  zookeeper::client
  ]

default_attributes({
    # Must use sun java with hadoop
    :java => {
      :install_flavor => 'sun'
    },
    # Used to specify number of default reducers, etc. Override in your cluster role
    :cluster_size => 5,
  })
