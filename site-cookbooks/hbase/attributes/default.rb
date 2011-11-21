default[:hbase][:cluster_name]          = node[:cluster_name]

#
# Locations
#

default[:hbase][:home_dir]              = '/usr/lib/hbase'
default[:hbase][:tmp_dir]               = '/mnt/hbase/tmp'
default[:hbase][:conf_dir]              = '/etc/hbase/conf'
default[:hbase][:log_dir]               = "/var/log/hbase"
default[:hbase][:pid_dir]               = "/var/run/hbase" ## FIXME: was "/var/run/hadoop-0.20", verify this doesn't screw things up

default[:hbase][:exported_confs]        = [ "#{node[:hbase][:conf_dir]}/hbase-default.xml", "#{node[:hbase][:conf_dir]}/hbase-site.xml",]
default[:hbase][:export_jars]           = [ "#{node[:hbase][:home_dir]}/hbase-0.90.1-cdh3u0.jar", "#{node[:hbase][:home_dir]}/hbase-0.90.1-cdh3u0-tests.jar", ]

#
# Install
#

default[:apt][:cloudera][:force_distro] = nil # override distro name if cloudera doesn't have yours yet
default[:apt][:cloudera][:release_name] = 'cdh3u2'

# GID to use for the hbase user
default[:groups]['hbase'     ][:gid]    = 304

#
# Services
#

default[:hbase][:master      ][:service_state] = [:enable, :start]
default[:hbase][:regionserver][:service_state] = [:enable, :start]
default[:hbase][:stargate    ][:service_state] = [:enable, :start]


#
# Tunables
#

default[:hbase][:master][:java_heap_size_max]       = "1000m"
default[:hbase][:master][:gc_new_size]              = "256m"
default[:hbase][:master][:gc_tuning_opts]           = "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts"
default[:hbase][:master][:gc_log_opts]              = "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-master-gc.log"

default[:hbase][:regionserver][:java_heap_size_max] = "2000m"
default[:hbase][:regionserver][:gc_new_size]        = "256m"
default[:hbase][:regionserver][:gc_tuning_opts]     = "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts -XX:CMSInitiatingOccupancyFraction=88"
default[:hbase][:regionserver][:gc_log_opts]        = "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-regionserver-gc.log"

default[:hbase][:weekly_backup_tables]            = []
