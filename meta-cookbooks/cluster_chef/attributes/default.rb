
default[:cluster_chef][:conf_dir] = '/etc/cluster_chef'
default[:cluster_chef][:log_dir]  = '/var/log/cluster_chef'
default[:cluster_chef][:home_dir] = '/etc/cluster_chef'

default[:server_tuning][:ulimit][:default]         = {}

default[:cluster_chef][:thttpd][:port] = 6789
