
default[:apt][:cloudera][:force_distro] = nil # override distro name if cloudera doesn't have yours yet
default[:apt][:cloudera][:release_name] = 'cdh3u2'

# GID to use for the hbase user
default[:groups]['hbase'     ][:gid] = 304

# Where hbase should put tmp files
default[:hbase][:tmp_dir]                     = '/mnt/hbase/tmp' # NOTE: reverse
default[:hbase][:conf_dir]                    = '/etc/hbase/conf/'

default[:hbase][:exported_confs]              = [ "/etc/hbase/conf/hbase-default.xml", "/etc/hbase/conf/hbase-site.xml",]
default[:hbase][:export_jars]               = [ "/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar", "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar", ]

default[:hbase][:master_java_heap_size_max]            = "1000m"
default[:hbase][:master_gc_new_size]          = "256m"
default[:hbase][:master_gc_tuning_opts]       = "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts"
default[:hbase][:master_gc_log_opts]          = "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-master-gc.log"

default[:hbase][:regionserver_java_heap_size_max]      = "2000m"
default[:hbase][:regionserver_gc_new_size]    = "256m"
default[:hbase][:regionserver_gc_tuning_opts] = "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts -XX:CMSInitiatingOccupancyFraction=88"
default[:hbase][:regionserver_gc_log_opts]    = "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-regionserver-gc.log"
default[:hbase][:cluster_name]                = node[:cluster_name]
default[:hbase][:weekly_backup_tables] = []
