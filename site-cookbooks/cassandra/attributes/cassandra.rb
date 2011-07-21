# Make sure you define a cluster_size in roles/WHATEVER_cluster.rb
# default[:cluster_size] = 5

# The "cassandra" data bag "clusters" item defines keyspaces for the cluster named here:
 default[:cassandra][:cluster_name]                  = node[:cluster_name] || "Test"

#
# Make a databag called 'cassandra', with an element 'clusters'.
# Within that, define a hash named for your cluster (the setting right above).
# now a keyspace option
# default[:cassandra][:gc_grace]                      = 864_000
# - keys_cached:                        specifies the number of keys per sstable whose
#   locations we keep in memory in "mostly LRU" order.  (JUST the key
#   locations, NOT any column values.) Specify a fraction (value less
#   than 1) or an absolute number of keys to cache.  Defaults to 200000
#   keys.
# - rows_cached:                        specifies the number of rows whose entire contents we
#   cache in memory. Do not use this on ColumnFamilies with large rows,
#   or ColumnFamilies with high write:read ratios. Specify a fraction
#   (value less than 1) or an absolute number of rows to cache.
#   Defaults to 0. (i.e. row caching is off by default)
# - comment:                            used to attach additional human-readable information about
#   the column family to its definition.
# - read_repair_chance:                 specifies the probability with which read
#   repairs should be invoked on non-quorum reads.  must be between 0
#   and 1. defaults to 1.0 (always read repair).
# - preload_row_cache:                  If true, will populate row cache on startup.
#   Defaults to false.
# - gc_grace_seconds:                   specifies the time to wait before garbage
#   collecting tombstones (deletion markers). defaults to 864000 (10
#   days). See http://wiki.apache.org/cassandra/DistributedDeletes
#
default[:cassandra][:keyspaces]                     = {}

# Directories, hosts and ports
default[:cassandra][:cassandra_home]                = '/usr/local/share/cassandra'
default[:cassandra][:cassandra_conf]                = '/etc/cassandra'
default[:cassandra][:cassandra_user]                = 'cassandra'
default[:cassandra][:data_file_dirs]                = ["/data/db/cassandra"]
default[:cassandra][:commitlog_dir]                 = "/mnt/cassandra/commitlog"
default[:cassandra][:saved_caches_dir]              = "/var/lib/cassandra/saved_caches"
default[:cassandra][:listen_addr]                   = "localhost"
default[:cassandra][:storage_port]                  = 7000
default[:cassandra][:rpc_addr]                      = "localhost"
default[:cassandra][:rpc_port]                      = 9160
default[:cassandra][:jmx_port]                      = 12345         # moved from default of 8080 (conflicts with hadoop)
# Partitioning
default[:cassandra][:auto_bootstrap]                = 'false'
default[:cassandra][:authenticator]                 = "org.apache.cassandra.auth.AllowAllAuthenticator"
default[:cassandra][:authority]                     = "org.apache.cassandra.auth.AllowAllAuthority"
default[:cassandra][:hinted_handoff_enabled]        = 'true'
default[:cassandra][:max_hint_window_in_ms]         = 3600000
default[:cassandra][:hinted_handoff_throttle_delay_in_ms] = 50
default[:cassandra][:partitioner]                   = "org.apache.cassandra.dht.RandomPartitioner"       # "org.apache.cassandra.dht.OrderPreservingPartitioner"
default[:cassandra][:endpoint_snitch]               = "org.apache.cassandra.locator.SimpleSnitch"
default[:cassandra][:dynamic_snitch]                = 'true'
default[:cassandra][:initial_token]                 = ""
default[:cassandra][:seeds]                         = ["127.0.0.1"]
# Memory, Disk and Performance
default[:cassandra][:java_min_heap]                 = "128M"        # consider setting equal to max_heap in production
default[:cassandra][:java_max_heap]                 = "1650M"
default[:cassandra][:java_eden_heap]                = "1500M"
default[:cassandra][:disk_access_mode]              = "auto"
default[:cassandra][:concurrent_reads]              = 8             # 2 per core
default[:cassandra][:concurrent_writes]             = 32            # typical number of clients
default[:cassandra][:memtable_flush_writers]        = 1             # see comment in cassandra.yaml.erb
default[:cassandra][:memtable_flush_after]          = 60
default[:cassandra][:sliced_buffer_size]            = 64            # size of column slices
default[:cassandra][:thrift_framed_transport]       = 15            # default 15; fixes CASSANDRA-475, but make sure your client is happy (Set to nil for debugging)
default[:cassandra][:thrift_max_message_length]     = 16
default[:cassandra][:incremental_backups]           = false
default[:cassandra][:snapshot_before_compaction]    = false
default[:cassandra][:memtable_throughput]           = 64
default[:cassandra][:memtable_ops]                  = 0.3
default[:cassandra][:column_index_size]             = 64
default[:cassandra][:in_memory_compaction_limit]    = 64
default[:cassandra][:compaction_preheat_key_cache]  = true
default[:cassandra][:commitlog_rotation_threshold]  = 128
default[:cassandra][:commitlog_sync]                = "periodic"
default[:cassandra][:commitlog_sync_period]         = 10000
default[:cassandra][:flush_largest_memtables_at]    = 0.75
default[:cassandra][:reduce_cache_sizes_at]         = 0.85
default[:cassandra][:reduce_cache_capacity_to]      = 0.6
default[:cassandra][:rpc_timeout_in_ms]             = 10000
default[:cassandra][:rpc_keepalive]                 = "false"
default[:cassandra][:phi_convict_threshold]         = 8
default[:cassandra][:request_scheduler]             = 'org.apache.cassandra.scheduler.NoScheduler'
default[:cassandra][:throttle_limit]                = 80           # 2x (concurrent_reads + concurrent_writes)
default[:cassandra][:request_scheduler_id]          = 'keyspace'

# For install_from_release recipe
cassversion = "0.7.7"
default[:cassandra][:install_url] = "http://www.eng.lsu.edu/mirrors/apache/cassandra/#{cassversion}/apache-cassandra-#{cassversion}-bin.tar.gz"
# For install_from_git
default[:cassandra][:git_repo]                      = 'git://git.apache.org/cassandra.git'
# until ruby gem is updated, use cdd239dcf82ab52cb840e070fc01135efb512799
default[:cassandra][:git_revision]                  = 'cdd239dcf82ab52cb840e070fc01135efb512799' # 'HEAD'

# JNA deb location
default[:cassandra][:jna_deb_amd64_url] = "http://debian.riptano.com/maverick/pool/libjna-java_3.2.7-0~nmu.2_amd64.deb"

# MX4J Location (Version 3.0.2)
default[:cassandra][:mx4j_url] = "http://downloads.sourceforge.net/project/mx4j/MX4J%20Binary/3.0.2/mx4j-3.0.2.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fmx4j%2Ffiles%2F&ts=1303407638&use_mirror=iweb"

default[:cassandra][:mx4j_listen_addr] = "127.0.0.1"
default[:cassandra][:mx4j_listen_port] = "8081"

# see http://www.mail-archive.com/user@cassandra.apache.org/msg04447.html

# if node[:ec2] && node[:ec2][:instance_type]
#   cassandra_settings =
#     case node[:ec2][:instance_type]
#     when 'm1.small'   then { :java_max_heap =>  '-Xmx1024m' }
#     when 'c1.medium'  then { :java_max_heap =>  '-Xmx1024m' }
#     when 'm1.large'   then { :java_max_heap =>  '-Xmx5500m' }
#     when 'm2.xlarge'  then { :java_max_heap => '-Xmx15000m' }
#     when 'c1.xlarge'  then { :java_max_heap =>  '-Xmx5500m' }
#     when 'm1.xlarge'  then { :java_max_heap => '-Xmx12000m' }
#     when 'm2.2xlarge' then { :java_max_heap => '-Xmx30000m' }
#     when 'm2.4xlarge' then { :java_max_heap => '-Xmx60000m' }
#     else {}
#     end
# end
