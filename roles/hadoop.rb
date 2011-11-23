name        'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  java

  hadoop_cluster
  hadoop_cluster::add_cloudera_repo
  cluster_chef::dedicated_server_tuning
  hadoop_cluster::simple_dashboard
  ]

default_attributes({
    # Must use sun java with hadoop
    :java => {
      :install_flavor => 'sun'
    },
  })
