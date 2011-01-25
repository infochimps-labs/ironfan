name 'hadoop_worker'
description 'A combined role requiring the distributed parts of a hadoop cluster, namely tasktracker and datanode.'

run_list %w[
  role[hadoop_datanode]
  role[hadoop_tasktracker]
]
