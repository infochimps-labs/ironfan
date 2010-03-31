name 'hadoop_worker'
description 'runs one of many workers in fully-distributed mode.'
run_list *%w[
  ec2::filesystems
  hadoop_cluster::worker
  hadoop_cluster::ec2_conf
]

default_attributes({
  })
