name 'hadoop_namenode'
description 'runs a namenode in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  role[hadoop]
  hadoop_cluster::namenode
  cluster_chef::cluster_webfront
]
