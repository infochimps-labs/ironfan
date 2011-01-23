name 'hbase_regionserver'
description 'runs a zookeeper and hbase-master in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  zookeeper::client
  hbase::hbase_regionserver
]
