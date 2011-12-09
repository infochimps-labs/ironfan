
default[:elasticsearch][:cluster_name]            = "default"

#
# Locations
#

default[:elasticsearch][:home_dir]                = "/usr/local/share/elasticsearch"
default[:elasticsearch][:conf_dir]                = "/etc/elasticsearch"
default[:elasticsearch][:log_dir]                 = "/var/log/elasticsearch"
default[:elasticsearch][:lib_dir]                 = "/var/lib/elasticsearch"
default[:elasticsearch][:pid_dir]                 = "/var/run/elasticsearch"
#
default[:elasticsearch][:data_root]               = "/mnt/elasticsearch"

default[:elasticsearch][:raid][:devices]          = [ '/dev/sdb', '/dev/sdc', '/dev/sdd', '/dev/sde' ]
default[:elasticsearch][:raid][:use_raid]         = true

#
# User
#

default[:elasticsearch ][:user]                   = 'elasticsearch'
default[:users ]['elasticsearch'][:uid]           = 61021
default[:groups]['elasticsearch'][:gid]           = 61021

#
# Install
#

default[:elasticsearch][:version]                 = "0.18.5"
default[:elasticsearch][:release_url_checksum]    = nil
default[:elasticsearch][:release_url]             = "https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-:version:.tar.gz"
default[:elasticsearch][:git_repo]                = "https://github.com/elasticsearch/elasticsearch.git"
default[:elasticsearch][:plugins]                 = ["cloud-aws"]
#
# Services
#

default[:elasticsearch][:server][:run_state] = :stop

#
# Tunables
#

default[:elasticsearch][:java_home]               = "/usr/lib/jvm/java-6-sun/jre"     # sun java works way better for ES
default[:elasticsearch][:java_heap_size_max]      = 1000
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

default[:elasticsearch][:recovery_after_nodes]    = 2
default[:elasticsearch][:recovery_after_time]     = '5m'
default[:elasticsearch][:expected_nodes]          = 2

default[:elasticsearch][:fd_ping_interval]        = "2s"
default[:elasticsearch][:fd_ping_timeout]         = "60s"
default[:elasticsearch][:fd_ping_retries]         = 6

default[:elasticsearch][:http_ports]              = "9200-9300"
default[:elasticsearch][:api_port]                = "9300"
default[:elasticsearch][:jmx_dash_port]           = '9400-9500'
default[:elasticsearch][:proxy_port]              = "8200"
default[:elasticsearch][:proxy_hostname]          = "elasticsearch.yourdomain.com"


default[:tuning][:ulimit]['@elasticsearch'] = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }

# most of the log lines are manageable at level 'DEBUG'
# the voluminous ones are broken out separately
default[:elasticsearch][:log_level][:default]         = 'DEBUG'
default[:elasticsearch][:log_level][:index_store]     = 'INFO'  # lots of output but might be useful
default[:elasticsearch][:log_level][:action_shard]    = 'INFO'  # lots of output but might be useful
default[:elasticsearch][:log_level][:cluster_service] = 'INFO'  # lots of output but might be useful
