
# GID to use for the hbase user
default[:groups]['hbase'     ][:gid] = 304

# Where hbase should put tmp files
default[:hbase][:tmp_dir]                     = '/mnt/tmp/hbase'

default[:hbase][:master_heap_size]            = "1000m"
default[:hbase][:master_gc_new_size]          = "256m"
default[:hbase][:master_gc_tuning_opts]       = "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts"
default[:hbase][:master_gc_log_opts]          = "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-master-gc.log"

default[:hbase][:regionserver_heap_size]      = "2000m"
default[:hbase][:regionserver_gc_new_size]    = "256m"
default[:hbase][:regionserver_gc_tuning_opts] = "-XX:+UseConcMarkSweepGC -XX:+AggressiveOpts -XX:CMSInitiatingOccupancyFraction=88"
default[:hbase][:regionserver_gc_log_opts]    = "-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:/var/log/hbase/hbase-regionserver-gc.log"
default[:hbase][:cluster_name]                = node[:cluster_name]
default[:hbase][:weekly_backup_tables] = []

