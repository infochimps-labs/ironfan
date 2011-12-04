name        'cassandra_datanode'
description 'Part of a cassandra database'

run_list *%w[
  java
  runit
  boost
  thrift
  ntp
  cassandra
  cassandra::install_from_release
  cassandra::autoconf
  cassandra::server
  cassandra::jna_support
  ]

#  cassandra::mx4j

# Attributes applied if the node doesn't have it set already.
default_attributes({
    :cassandra => {
      :auto_bootstrap    => true,
      :jmx_dash_port          => 12345,
      :concurrent_reads  => 4,
      :concurrent_writes => 64,
      :commitlog_sync    => 'periodic',
      :data_dirs    => ["/data/db/cassandra"],
    }
  })
