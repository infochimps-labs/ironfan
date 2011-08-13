name 'hadoop_jobtracker'
description 'runs a jobtracker in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  role[hadoop]
  hadoop_cluster::jobtracker
  cluster_chef::cluster_webfront
]
