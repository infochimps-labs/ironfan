name 'hadoop_namenode_initial_setup'
description 'Janitorial tasks required on initial construction of a hadoop cluster. REMOVE THIS ROLE AFTER CLUSTER IS SUCCESSFULLY LAUNCHED'

run_list(%w[
  hadoop_cluster::bootstrap_format_namenode
  hadoop_cluster::wait_on_hdfs_safemode
  hadoop_cluster::bootstrap_hdfs_dirs
])
