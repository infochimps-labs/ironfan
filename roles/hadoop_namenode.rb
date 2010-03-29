name 'hadoop_namenode'
description 'runs a namenode in fully-distributed mode. There should be exactly one of these per cluster.'
run_list 'cdh::ec2_conf', 'cdh::namenode'
