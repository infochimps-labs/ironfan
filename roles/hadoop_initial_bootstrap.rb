name 'hadoop_initial_bootstrap'
description 'Janitorial tasks required on initial construction of a hadoop cluster. REMOVE THIS ROLE AFTER CLUSTER IS SUCCESSFULLY LAUNCHED'

run_list(%w[
  hadoop_cluster::wait_on_hdfs_safemode
  hadoop_cluster::bootstrap_hdfs_dirs
])
