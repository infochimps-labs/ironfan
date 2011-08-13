name 'hadoop_secondarynamenode'
description 'runs a secondarynamenode in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  role[hadoop]
  hadoop_cluster::secondarynamenode
]
