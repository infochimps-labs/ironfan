name 'hdfs_fuse'
description 'runs hdfs fuse daemon'

run_list %w[
  hadoop_cluster::hdfs_fuse
]

default_attributes({
  })
