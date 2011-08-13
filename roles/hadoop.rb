name        'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  hadoop_cluster
  hadoop_cluster::cluster_conf
  hadoop_cluster::ec2_conf

  hadoop_cluster::hadoop_dir_perms
  cluster_chef::dedicated_server_tuning
  zookeeper::client
  ]

default_attributes({
    # Must use sun java with hadoop
    :java => {
      :install_flavor => 'sun'
    },
  })
