name 'hadoop_master'
description 'A combined role requiring all the supervisory components of a hadoop cluster: Namenode, Jobtracker, Secondarynamenode. This does *not* also define a tasktracker or datanode -- add the hadoop_worker role for that.'

run_list %w[
  role[hadoop_namenode]
  role[hadoop_secondarynamenode]
  role[hadoop_jobtracker]
]
