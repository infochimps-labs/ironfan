name        'flume_node'
description 'flume node'

run_list(*%w[
  flume::node
  flume::jruby_plugin
])

#  flume::hbase_sink_plugin
