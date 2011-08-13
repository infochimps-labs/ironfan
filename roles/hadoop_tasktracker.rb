name 'hadoop_tasktracker'
description 'Hadoop Tasktracker in fully-distributed mode. Usually used in conjunction with Hadoop Datanode for basic clients.'

run_list *%w[
  role[hadoop]
  hadoop_cluster::tasktracker
]
