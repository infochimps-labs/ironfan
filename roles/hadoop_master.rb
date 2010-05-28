name 'hadoop_master'
description 'runs a namenode, secondarynamenode, jobtracker and webfront in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  hadoop_cluster::ec2_conf
  hadoop_cluster::namenode
  hadoop_cluster::jobtracker
  hadoop_cluster::hadoop_webfront
]

default_attributes({
  })
