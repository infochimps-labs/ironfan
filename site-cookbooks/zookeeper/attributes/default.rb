
default[:apt][:cloudera][:force_distro]      = nil # override distro name if cloudera doesn't have yours yet
default[:apt][:cloudera][:release_name]      = 'cdh3u2'

default[:groups]['zookeeper' ][:gid]         = 305

default[:zookeeper][:data_dir]               = '/var/zookeeper'
default[:zookeeper][:log_dir]                = '/var/log/zookeeper'
default[:zookeeper][:cluster_name]           = node[:cluster_name]
default[:zookeeper][:max_client_connections] = 30

default[:zookeeper][:export_jars]          = [  "/usr/lib/zookeeper/zookeeper.jar", ]
