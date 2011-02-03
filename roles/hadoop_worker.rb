name 'hadoop_worker'
description 'runs one of many workers in fully-distributed mode.'

run_list *%w[
  hadoop_cluster
  hadoop_cluster::ec2_conf
  hadoop_cluster::hadoop_dir_perms
  hadoop_cluster::datanode
  hadoop_cluster::tasktracker
  hadoop_cluster::system_internals
  pig::apache_plus_cloudera_best_friends_forever
  zookeeper
]
