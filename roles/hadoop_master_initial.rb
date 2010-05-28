name 'hadoop_master_initial'
description 'Initial setup of Hadoop and HDFS'

run_list %w[
  hadoop_cluster::format_namenode_once
  hadoop_cluster::std_hdfs_dirs
  hadoop_cluster::hadoop_dir_perms
]

default_attributes({
  })
