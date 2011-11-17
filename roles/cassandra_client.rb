name        'cassandra_client'
description 'Part of a cassandra database'

run_list *%w[
  java
  runit
  boost
  thrift
  cassandra
  cassandra::install_from_release
  cassandra::autoconf
  cassandra::client
  ]

# Attributes applied if the node doesn't have it set already.
default_attributes({
    :cassandra => {
      :auto_bootstrap    => true,
      :jmx_port          => 12345,
      :concurrent_reads  => 4,
      :concurrent_writes => 64,
      :commitlog_sync    => 'periodic',
      :data_dirs    => ["/data/db/cassandra"],
    }
  })
