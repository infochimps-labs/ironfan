
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

# configuration data for plugins.
# node[:flume][:plugins][:some_plugin][:classes]    = [ 'java.lang.String' ]
# node[:flume][:plugins][:some_plugin][:classpath]  = [ "/usr/lib/jruby/jruby.jar" ]
# node[:flume][:plugins][:some_plugin][:java_opts]  = [ "-Dsomething.special=1" ]
default[:flume][:plugins] = {}

# classes to include as plugins
default[:flume][:classes] = []

# jars and dirs to put on FLUME_CLASSPATH
default[:flume][:classpath] = []

# pass in extra options to the java virtual machine
default[:flume][:java_opts] = []

default[:flume][:collector] = {}
