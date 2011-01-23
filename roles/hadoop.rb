name        'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  hadoop_cluster
  hadoop_cluster::cluster_conf
  hadoop_cluster::ec2_conf
  hadoop_cluster::hadoop_dir_perms
  cluster_chef::dedicated_server_tuning
  pig::install_from_package
  zookeeper::client
  ]
