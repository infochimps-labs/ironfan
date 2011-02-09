
#By default, flume plays as a part of the cluster the machine
#belongs to.
default[:flume][:cluster_name] = node[:cluster_name]

# By default, flume installs its own zookeeper instance.
# Set :external_zookeeper to "true". The recipe will
# work out which machines are in the zookeeper quorum
# based on cluster membership. (See [:flume][:cluster_name]
# above. 
default[:flume][:master][:external_zookeeper] = false
default[:flume][:master][:zookeeper_port] = 2181  

default[:flume][:plugin_classes] = []
default[:flume][:classpath] = []
