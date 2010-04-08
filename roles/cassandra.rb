name        'cassandra_node'
description 'Part of a cassandra database'

run_list *%w[
  java
  runit
  boost
  thrift
  cassandra::install_from_release
  cassandra::autoconf
  cassandra
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
  })
