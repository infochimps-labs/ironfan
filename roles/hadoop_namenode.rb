name 'hadoop_namenode'
description 'runs a namenode in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  hadoop_cluster::namenode
  hadoop_cluster::hadoop_webfront
]
