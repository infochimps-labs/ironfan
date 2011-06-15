default[:elasticsearch][:version]                 = "0.13.1"
# default[:elasticsearch][:checksum]              = '67a5b6240c27db666b5d2b48cdc26b91d64e8f2e950c6383273e47a6f4020da4'

default[:elasticsearch][:cluster_name]            = "default"

default[:elasticsearch][:install_dir]             = "/usr/local/share/elasticsearch"
default[:elasticsearch][:data_root]               = "/mnt/elasticsearch"
default[:elasticsearch][:java_home]               = "/usr/lib/jvm/java-6-sun/jre"     # sun java works way better for ES

default[:elasticsearch][:git_repo]                = "https://github.com/elasticsearch/elasticsearch.git"

default[:elasticsearch][:heap_size]               = 1000
default[:elasticsearch][:ulimit_mlock]            = nil  # locked memory limit -- set to unlimited to lock heap into memory on linux machines

default[:elasticsearch][:default_replicas]        =  1   # replicas are in addition to the original, so 1 replica means 2 copies of each shard
default[:elasticsearch][:default_shards]          =  6   # 6 shards per index * 2 replicas distributes evenly across 3, 4, 6 or 12 nodes
default[:elasticsearch][:flush_threshold]         = 5000
default[:elasticsearch][:index_buffer_size]       = "10%"  # can be a percent ("10%") or a number ("128m")
default[:elasticsearch][:merge_factor]            = 10
default[:elasticsearch][:max_thread_count]        = 4    # Twice the recommended value, max allowed by max_merge_count = 4
default[:elasticsearch][:term_index_interval]     = 128
default[:elasticsearch][:refresh_interval]        = "1s"
default[:elasticsearch][:snapshot_interval]       = '-1'
default[:elasticsearch][:snapshot_on_close]       = 'false'

default[:elasticsearch][:seeds]                   = nil

default[:elasticsearch][:recovery_after_nodes]     = 2
default[:elasticsearch][:recovery_after_time]      = '5m'
default[:elasticsearch][:expected_nodes]           = 2

default[:elasticsearch][:fd_ping_interval]        = "1s"
default[:elasticsearch][:fd_ping_timeout]         = "30s"
default[:elasticsearch][:fd_ping_retries]         = 3

default[:elasticsearch][:jmx_port]                = '9400-9500'

# most of the log lines are manageable at level 'DEBUG'
# the voluminous ones are broken out separately
default[:elasticsearch][:log_level][:default]         = 'DEBUG'
default[:elasticsearch][:log_level][:index_store]     = 'INFO'  # lots of output but might be useful
default[:elasticsearch][:log_level][:action_shard]    = 'INFO'  # lots of output but might be useful
default[:elasticsearch][:log_level][:cluster_service] = 'INFO'  # lots of output but might be useful
