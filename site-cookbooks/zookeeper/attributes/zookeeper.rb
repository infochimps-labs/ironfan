

default[:groups]['zookeeper' ][:gid] = 305
default[:zookeeper][:data_dir] = '/var/zookeeper'
default[:zookeeper][:cluster_name] = node[:cluster_name]
default[:zookeeper][:log_dir] = '/var/log/zookeeper'
default[:zookeeper][:max_client_connections] = 30

