# -*- coding: utf-8 -*-
default[:hadoop][:hadoop_handle] = 'hadoop-0.20'
default[:hadoop][:cdh_version]   = 'cdh3u2'
default[:hadoop][:deb_version]   = '0.20.2+923.142-1~maverick-cdh3'
default[:hadoop][:cloudera_distro_name] = nil # override distro name if cloudera doesn't have yours yet

# What states to set for services.
#   :enable => enabled service to run at boot.
#   :start  => ensure it's started and running.
# You want to bring then big daemons up deliberately on initial start --
# override in your cluster definition when things are stable.
default[:service_states][:hadoop_namenode]           = []
default[:service_states][:hadoop_secondarynamenode ] = []
default[:service_states][:hadoop_jobtracker]         = []

# These we can do [:enable,:start] -- though on a full-cluster stop/start (or
#   any other time the main daemons' ip address changes) you may need to
#   converge chef and then restart them all.
default[:service_states][:hadoop_datanode]           = [:enable, :start]
default[:service_states][:hadoop_tasktracker]        = [:enable, :start]

# Make sure you define a cluster_size in roles/WHATEVER_cluster.rb
default[:cluster_size] = 5

default[:hadoop][:dfs_replication             ] =  3
default[:hadoop][:reduce_parallel_copies      ] = 10
default[:hadoop][:tasktracker_http_threads    ] = 32
default[:hadoop][:jobtracker_handler_count    ] = 40
default[:hadoop][:namenode_handler_count      ] = 40
default[:hadoop][:datanode_handler_count      ] =  8

default[:hadoop][:compress_output           ] = 'true'
default[:hadoop][:compress_output_type      ] = 'BLOCK'
default[:hadoop][:compress_output_codec     ] = 'org.apache.hadoop.io.compress.DefaultCodec'
default[:hadoop][:compress_mapout           ] = 'true'
default[:hadoop][:compress_mapout_codec     ] = 'org.apache.hadoop.io.compress.DefaultCodec' # try instead: 'org.apache.hadoop.io.compress.SnappyCodec'

default[:hadoop][:mapred_userlog_retain_hours ] = 24
default[:hadoop][:mapred_jobtracker_completeuserjobs_maximum ] = 100

# Other recipes can add to this under their own special key, for instance
#  node[:hadoop][:extra_classpaths][:hbase] = '/usr/lib/hbase/hbase.jar:/usr/lib/hbase/lib/zookeeper.jar:/usr/lib/hbase/conf'
#
default[:hadoop][:extra_classpaths]  = { }

# uses /etc/default/hadoop-0.20 to set the hadoop daemon's heapsize
default[:hadoop][:daemon_heapsize]       = 1000
# these will be set to the daemon heapsize if nil
default[:hadoop][:namenode_heapsize]          = nil
default[:hadoop][:secondarynamenode_heapsize] = nil
default[:hadoop][:jobtracker_heapsize]        = nil

default[:groups]['hadoop'    ][:gid] = 300
default[:groups]['supergroup'][:gid] = 301
default[:groups]['hdfs'      ][:gid] = 302
default[:groups]['mapred'    ][:gid] = 303

# persistent dirs hold the HDFS, namenode metadata, and so forth.
default[:hadoop][:persistent_dirs] = %w[ /mnt/hadoop ]
# scratch dirs hold the mapreduce local dirs, logs, and so forth.
default[:hadoop][:scratch_dirs]    = %w[ /mnt/hadoop ]

# Other hadoop settings
default[:hadoop][:max_balancer_bandwidth]     = 1048576  # bytes per second -- 1MB/s by default
# fs.inmemory.size.mb  # default XX

# You may wish to set the following to the same as your HDFS block size, esp if
# you're seeing issues with s3:// turning 1TB files into 30_000+ map tasks
#
default[:hadoop][:min_split_size]  = (128 * 1024 * 1024)
default[:hadoop][:s3_block_size]   = (128 * 1024 * 1024)
default[:hadoop][:hdfs_block_size] = (128 * 1024 * 1024)

#
# Tune cluster settings for size of instance
#
# These settings are mostly taken from the cloudera hadoop-ec2 scripts,
# informed by the
#
#   numMappers  M := numCores * 1.5
#   numReducers R := numCores max 4
#   java_Xmx       := 0.75 * (TotalRam / (numCores * 1.5) )
#   ulimit         := 3 * java_Xmx
#
# With 1.5*cores tasks taking up max heap, 75% of memory is occupied.  If your
# job is memory-bound on both map and reduce side, you *must* reduce the number
# of map and reduce tasks for that job to less than 1.5*cores together.  using
# mapred.max.maps.per.node and mapred.max.reduces.per.node, or by setting
# java_child_opts.
#
# It assumes EC2 instances with EBS-backed volumes
# If your cluster is heavily used and has many cores/machine (almost always running a full # of maps and reducers) turn down the number of mappers.
# If you typically run from S3 (fully I/O bound) increase the number of maps + reducers moderately.
# In both cases, adjust the memory settings accordingly.
#
#
# FIXME: The below parameters are calculated for each node.
#   The max_map_tasks and max_reduce_tasks settings apply per-node, no problem here
#   The remaining ones (java_child_opts, io_sort_mb, etc) are applied *per-job*:
#   if you launch your job from an m2.xlarge on a heterogeneous cluster, all of
#   the tasks will kick off with -Xmx4531m and so forth, regardless of the RAM
#   on that machine.
#
# Also, make sure you're
#
hadoop_performance_settings =
  case node[:ec2][:instance_type]
  when 't1.micro'   then { :max_map_tasks =>  1, :max_reduce_tasks => 1, :java_child_opts =>  '-Xmx256m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 100, }
  when 'm1.small'   then { :max_map_tasks =>  2, :max_reduce_tasks => 1, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 160, }
  when 'c1.medium'  then { :max_map_tasks =>  3, :max_reduce_tasks => 2, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 160, }
  when 'm1.large'   then { :max_map_tasks =>  3, :max_reduce_tasks => 2, :java_child_opts => '-Xmx2432m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit =>  7471104, :io_sort_factor => 25, :io_sort_mb => 256, }
  when 'c1.xlarge'  then { :max_map_tasks => 10, :max_reduce_tasks => 4, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 20, :io_sort_mb => 160, }
  when 'm1.xlarge'  then { :max_map_tasks =>  6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx1920m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit =>  5898240, :io_sort_factor => 25, :io_sort_mb => 256, }
  when 'm2.xlarge'  then { :max_map_tasks =>  4, :max_reduce_tasks => 2, :java_child_opts => '-Xmx4531m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 32, :io_sort_mb => 256, }
  when 'm2.2xlarge' then { :max_map_tasks =>  6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 32, :io_sort_mb => 256, }
  when 'm2.4xlarge' then { :max_map_tasks => 12, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 40, :io_sort_mb => 256, }
  else
    cores        = node[:cpu][:total].to_i
    ram          = node[:memory][:total].to_i
    Chef::Log.info("Couldn't set performance parameters from instance type, estimating from #{cores} cores and #{ram} ram")
    n_mappers    = (cores >= 8 ? cores : cores * 2)
    n_reducers   = cores
    heap_size    = 0.75 * (ram.to_f / 1000) / (n_mappers + n_reducers)
    heap_size    = [550, heap_size.to_i].max
    child_ulimit = 2 * heap_size * 1024
    { :max_map_tasks => n_mappers, :max_reduce_tasks => n_reducers, :java_child_opts => "-Xmx#{heap_size}m", :java_child_ulimit => child_ulimit, :io_sort_factor => 10, :io_sort_mb => 100, }
  end

# (Mappers+Reducers)*ChildTaskHeap + DNheap + TTheap + 3GB + RSheap + OtherServices'

Chef::Log.info(["Hadoop mapreduce tuning", hadoop_performance_settings].inspect)

hadoop_performance_settings.each{|k,v| set[:hadoop][k] = v }
