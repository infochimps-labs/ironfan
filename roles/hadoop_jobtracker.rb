name 'hadoop_jobtracker'
description 'runs a hadoop jobtracker in fully-distributed mode. There should be exactly one of these per cluster.'
run_list 'cdh::jobtracker'
