name        'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  java

  hadoop_cluster
  hadoop_cluster::ec2_conf
  cluster_chef::dedicated_server_tuning

  ]

default_attributes({
    # Must use sun java with hadoop
    :java => {
      :install_flavor => 'sun'
    },
  })
