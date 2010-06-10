# The "cassandra" data bag "clusters" item defines keyspaces for the cluster named here:
set[:cassandra][:cluster_name]                      = node[:cluster_name] || "Test"
default[:cassandra][:keyspaces]                     = {}
# Directories
default[:cassandra][:data_file_dirs]                = ["/data/db/cassandra"]
default[:cassandra][:commit_log_dir]                = "/var/lib/cassandra/commitlog"
default[:cassandra][:callout_location]              = "/var/lib/cassandra/callouts"
default[:cassandra][:staging_file_dir]              = "/var/lib/cassandra/staging"
# Partitioning
default[:cassandra][:auto_bootstrap]                = true
default[:cassandra][:authenticator]                 = "org.apache.cassandra.auth.AllowAllAuthenticator"
default[:cassandra][:partitioner]                   = "org.apache.cassandra.dht.RandomPartitioner"       # "org.apache.cassandra.dht.OrderPreservingPartitioner"
default[:cassandra][:initial_token]                 = ""
default[:cassandra][:seeds]                         = ["127.0.0.1"]
# Miscellaneous
default[:cassandra][:rpc_timeout]                   = 5000
default[:cassandra][:commit_log_rotation_threshold] = 128
default[:cassandra][:jmx_port]                      = 8080
default[:cassandra][:listen_addr]                   = "localhost"
default[:cassandra][:storage_port]                  = 7000
default[:cassandra][:thrift_addr]                   = "localhost"
default[:cassandra][:thrift_port]                   = 9160
default[:cassandra][:thrift_framed_transport]       = false
# Memory, Disk and Performance
default[:cassandra][:disk_access_mode]              = "auto"
default[:cassandra][:sliced_buffer_size]            = 64
default[:cassandra][:flush_data_buffer_size]        = 32
default[:cassandra][:flush_index_buffer_size]       = 8
default[:cassandra][:column_index_size]             = 64
default[:cassandra][:memtable_throughput]           = 64
default[:cassandra][:binary_memtable_throughput]    = 256
default[:cassandra][:memtable_ops]                  = 0.3
default[:cassandra][:memtable_flush_after]          = 60
default[:cassandra][:concurrent_reads]              = 8
default[:cassandra][:concurrent_writes]             = 32
default[:cassandra][:commit_log_sync]               = "periodic"
default[:cassandra][:commit_log_sync_period]        = 10000
default[:cassandra][:gc_grace]                      = 864000
# Install from release
default[:cassandra][:install_url] = "http://apache.mirrors.tds.net/cassandra/0.6.1/apache-cassandra-0.6.1-bin.tar.gz"

