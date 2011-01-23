name 'hadoop_datanode'
description 'Hadoop Datanode in fully-distributed mode. Usually used in conjunction with Hadoop Tasktracker for basic clients.'

run_list *%w[
  role[hadoop]
  hadoop_cluster::datanode
]
