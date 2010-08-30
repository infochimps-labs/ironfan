
name 'hadoop_worker'
description 'runs one of many workers in fully-distributed mode.'
run_list *%w[
  hadoop_cluster
  hadoop_cluster::ec2_conf
  hadoop_cluster::hadoop_dir_perms
  hadoop_cluster::worker
  hadoop_cluster::system_internals
  pig::install_from_package
]

default_attributes({
  })
