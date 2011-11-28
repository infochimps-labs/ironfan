

#By default, flume plays as a part of the cluster the machine
#belongs to.
default[:flume][:cluster_name] = node[:cluster_name]

default[:flume][:data_dir] = "/data/db/flume"

#
# Locations
#

default[:flume][:home_dir]              = '/usr/lib/flume'
# default[:flume][:tmp_dir]               = '/mnt/flume/tmp'
default[:flume][:conf_dir]              = '/etc/flume/conf'
default[:flume][:log_dir]               = "/var/log/flume"
default[:flume][:pid_dir]               = "/var/run/flume"

#
# Install
#

default[:apt][:cloudera][:force_distro] = nil # override distro name if cloudera doesn't have yours yet
default[:apt][:cloudera][:release_name] = 'cdh3u2'

#
# Services
#

default[:flume][:master  ][:run_state] = :stop
default[:flume][:node    ][:run_state] = :stop


#
# Tunables
#

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

# Set the following two attributes to allow writing to s3 buckets:
default[:flume][:aws_access_key] = nil
default[:flume][:aws_secret_key] = nil
