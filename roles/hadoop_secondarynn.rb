name 'hadoop_secondarynn'
description 'runs a secondarynn in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  role[hadoop]
  hadoop_cluster::secondarynn
]
