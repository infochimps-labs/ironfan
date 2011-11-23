
# Other hadoop settings

# Make sure you define a cluster_size in roles/WHATEVER_cluster.rb
default[:cluster_size] = 5

# You may wish to set the following to the same as your HDFS block size, esp if
# you're seeing issues with s3:// turning 1TB files into 30_000+ map tasks
#
default[:hadoop][:min_split_size]  = (128 * 1024 * 1024)
default[:hadoop][:s3_block_size]   = (128 * 1024 * 1024)
default[:hadoop][:hdfs_block_size] = (128 * 1024 * 1024)
default[:hadoop][:dfs_replication] =  3

default[:hadoop][:namenode   ][:handler_count]       = 40
default[:hadoop][:jobtracker ][:handler_count]       = 40
default[:hadoop][:datanode   ][:handler_count]       =  8
default[:hadoop][:tasktracker][:http_threads ]       = 32
default[:hadoop][:reducer_parallel_copies    ]       = 10

default[:hadoop][:compress_output      ]             = 'false'
default[:hadoop][:compress_output_type ]             = 'BLOCK'
default[:hadoop][:compress_output_codec]             = 'org.apache.hadoop.io.compress.DefaultCodec'
default[:hadoop][:compress_mapout      ]             = 'true'
default[:hadoop][:compress_mapout_codec]             = 'org.apache.hadoop.io.compress.DefaultCodec' # try instead: 'org.apache.hadoop.io.compress.SnappyCodec'

# uses /etc/default/hadoop-0.20 to set the hadoop daemon's java_heap_size_max
default[:hadoop][:java_heap_size_max]                = 1000
default[:hadoop][:namenode    ][:java_heap_size_max] = nil
default[:hadoop][:secondarynn ][:java_heap_size_max] = nil
default[:hadoop][:jobtracker  ][:java_heap_size_max] = nil
default[:hadoop][:datanode    ][:java_heap_size_max] = nil
default[:hadoop][:tasktracker ][:java_heap_size_max] = nil

# bytes per second -- 1MB/s by default
default[:hadoop][:max_balancer_bandwidth]            = 1048576

# how long to keep jobtracker logs around
default[:hadoop][:log_retention_hours ]              = 24

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
  when 'm1.small'   then { :max_map_tasks =>  2, :max_reduce_tasks => 1, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 100, }
  when 'c1.medium'  then { :max_map_tasks =>  3, :max_reduce_tasks => 2, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 100, }
  when 'm1.large'   then { :max_map_tasks =>  3, :max_reduce_tasks => 2, :java_child_opts => '-Xmx2432m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit =>  7471104, :io_sort_factor => 25, :io_sort_mb => 250, }
  when 'c1.xlarge'  then { :max_map_tasks => 10, :max_reduce_tasks => 4, :java_child_opts =>  '-Xmx870m -Xss128k',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 20, :io_sort_mb => 200, }
  when 'm1.xlarge'  then { :max_map_tasks =>  6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx1920m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit =>  5898240, :io_sort_factor => 25, :io_sort_mb => 250, }
  when 'm2.xlarge'  then { :max_map_tasks =>  4, :max_reduce_tasks => 2, :java_child_opts => '-Xmx4531m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 32, :io_sort_mb => 250, }
  when 'm2.2xlarge' then { :max_map_tasks =>  6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 32, :io_sort_mb => 256, }
  when 'm2.4xlarge' then { :max_map_tasks => 12, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 40, :io_sort_mb => 256, }
  else
    cores        = node[:cpu   ][:total].to_i
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

hadoop_performance_settings.each{|k,v| set[:hadoop][k] = v }
