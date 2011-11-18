name        'flume_node'
description 'flume node'

run_list(*%w[
  hbase
  flume::node
  flume::jruby_plugin
  flume::hbase_sink_plugin
])
