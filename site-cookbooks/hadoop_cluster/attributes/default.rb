# -*- coding: utf-8 -*-

# This file describes
#
#
# See hadoop_cluster/attributes/tunables.rb for the hairy, hairy tuning variables.

#
# Services
#

# What states to set for services.
#
# You want to bring the big daemons up deliberately on initial start.
#   Override in your cluster definition when things are stable.
default[:hadoop][:namenode    ][:run_state]  = :stop
default[:hadoop][:secondarynn ][:run_state]  = :stop
default[:hadoop][:jobtracker  ][:run_state]  = :stop
#
# You can just kick off the worker daemons, they'll retry. On a full-cluster
#   stop/start (or any other time the main daemons' ip address changes) however
#   you will need to converge chef and then restart them all.
default[:hadoop][:datanode    ][:run_state]  = :start
default[:hadoop][:tasktracker ][:run_state]  = :start

default[:hadoop][:hdfs_fuse   ][:run_state]  = :stop
default[:hadoop][:balancer    ][:run_state]  = :stop

#
# Locations
#

#
# These are handled by mountable_volumes, which imprints them on the node.
# If you set an explicit value it will be used and no discovery is done.
#
# Chef Attr                    Owner           Permissions  Path                                     Hadoop Attribute
# [:namenode   ][:data_dir]    hdfs:hadoop     drwx------   {persistent_vols}/hadoop/hdfs/name       dfs.name.dir
# [:sec..node  ][:data_dir]    hdfs:hadoop     drwxr-xr-x   {persistent_vols}/hadoop/hdfs/secondary  fs.checkpoint.dir
# [:datanode   ][:data_dir]    hdfs:hadoop     drwxr-xr-x   {persistent_vols}/hadoop/hdfs/data       dfs.data.dir
# [:tasktracker][:scratch_dir] mapred:hadoop   drwxr-xr-x   {scratch_vols   }/hadoop/hdfs/name       mapred.local.dir
# [:jobtracker ][:system_hdfsdir]  mapred:hadoop   drwxr-xr-x   {!!HDFS!!       }/hadoop/mapred/system   mapred.system.dir
# [:jobtracker ][:staging_hdfsdir] mapred:hadoop   drwxr-xr-x   {!!HDFS!!       }/hadoop/mapred/staging  mapred.system.dir
#
# Important: In CDH3, the mapred.system.dir directory must be located inside a directory that is owned by mapred. For example, if mapred.system.dir is specified as /mapred/system, then /mapred must be owned by mapred. Don't, for example, specify /mrsystem as mapred.system.dir because you don't want / owned by mapred.
#
default[:hadoop][:namenode   ][:data_dirs]       = []
default[:hadoop][:secondarynn][:data_dirs]       = []
default[:hadoop][:jobtracker ][:system_hdfsdir]  = '/hadoop/mapred/system' # note: on the HDFS
default[:hadoop][:jobtracker ][:staging_hdfsdir] = '/hadoop/mapred/system' # note: on the HDFS
default[:hadoop][:datanode   ][:data_dirs]       = []
default[:hadoop][:tasktracker][:scratch_dirs]    = []

default[:hadoop][:home_dir] = "/usr/lib/hadoop"
default[:hadoop][:conf_dir] = "/etc/hadoop/conf"
default[:hadoop][:pid_dir]  = "/var/run/hadoop"
default[:hadoop][:log_dir]  = nil
default[:hadoop][:tmp_dir]  = nil


default[:hadoop][:namenode   ][:port]              =  8020
default[:hadoop][:jobtracker ][:port]              =  8021
default[:hadoop][:datanode   ][:port]              = 50010
default[:hadoop][:datanode   ][:ipc_port]          = 50020

default[:hadoop][:namenode   ][:dash_port]         = 50070
default[:hadoop][:secondarynn][:dash_port]         = 50090
default[:hadoop][:jobtracker ][:dash_port]         = 50030
default[:hadoop][:datanode   ][:dash_port]         = 50075
default[:hadoop][:tasktracker][:dash_port]         = 50060

default[:hadoop][:namenode   ][:jmx_dash_port]     = 8004
default[:hadoop][:secondarynn][:jmx_dash_port]     = 8005
default[:hadoop][:jobtracker ][:jmx_dash_port]     = 8008
default[:hadoop][:datanode   ][:jmx_dash_port]     = 8006
default[:hadoop][:tasktracker][:jmx_dash_port]     = 8009
default[:hadoop][:balancer   ][:jmx_dash_port]     = 8007

default[:java][:java_home] = '/usr/lib/jvm/java-6-sun/jre'

#
# Users
#

default[:groups]['hadoop'     ][:gid]   = 300
default[:groups]['supergroup' ][:gid]   = 301

default[:users ]['hdfs'       ][:uid]   = 302
default[:groups]['hdfs'       ][:gid]   = 302

default[:users ]['mapred'     ][:uid]   = 303
default[:groups]['mapred'     ][:gid]   = 303

default[:hadoop][:user]  = 'hdfs'
default[:hadoop][:namenode    ][:user]  = 'hdfs'
default[:hadoop][:secondarynn ][:user]  = 'hdfs'
default[:hadoop][:jobtracker  ][:user]  = 'mapred'
default[:hadoop][:datanode    ][:user]  = 'hdfs'
default[:hadoop][:tasktracker ][:user]  = 'mapred'

#
# Install
#

default[:hadoop][:handle]               = 'hadoop-0.20'
default[:hadoop][:deb_version]          = '0.20.2+923.142-1~maverick-cdh3'
default[:apt][:cloudera][:force_distro] = nil # override distro name if cloudera doesn't have yours yet
default[:apt][:cloudera][:release_name] = 'cdh3u2'

#
# System
#

default[:server_tuning][:ulimit]['hdfs']   = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }
default[:server_tuning][:ulimit]['hbase']  = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }
default[:server_tuning][:ulimit]['mapred'] = { :nofile => { :both => 32768 }, :nproc => { :both => 50000 } }

#
# Integration
#

# Other recipes can add to this under their own special key, for instance
#  node[:hadoop][:extra_classpaths][:hbase] = '/usr/lib/hbase/hbase.jar:/usr/lib/hbase/lib/zookeeper.jar:/usr/lib/hbase/conf'
default[:hadoop][:extra_classpaths]  = { }
