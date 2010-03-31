name 'hadoop_master'
description 'runs a namenode, secondarynamenode, jobtracker and webfront in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  ec2::filesystems
  cdh::namenode
  cdh::jobtracker
  cdh::hadoop_webfront
  cdh::ec2_conf
  cdh::make_standard_hdfs_dirs
]

default_attributes({
  })
