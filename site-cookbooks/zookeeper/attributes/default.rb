
#
# Locations
#

default[:zookeeper][:home_dir]               = '/usr/lib/zookeeper'
default[:zookeeper][:data_dir]               = '/var/zookeeper'
default[:zookeeper][:log_dir]                = '/var/log/zookeeper'

default[:groups]['zookeeper' ][:gid]         = 305

default[:zookeeper][:cluster_name]           = node[:cluster_name]

#
# Install
#

default[:apt][:cloudera][:force_distro]      = nil # override distro name if cloudera doesn't have yours yet
default[:apt][:cloudera][:release_name]      = 'cdh3u2'
default[:zookeeper][:export_jars]            = [ ::File.join(node[:zookeeper][:home_dir], "zookeeper.jar"), ]

#
# Tunables
#

default[:zookeeper][:max_client_connections] = 30
