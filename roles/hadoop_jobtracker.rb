name 'hadoop_jobtracker'
description 'runs a jobtracker in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  hadoop_cluster::jobtracker
  hadoop_cluster::hadoop_webfront
]
