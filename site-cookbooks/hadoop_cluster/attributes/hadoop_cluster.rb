# -*- coding: utf-8 -*-
default[:hadoop][:hadoop_handle] = 'hadoop-0.20'
default[:hadoop][:cdh_version]   = 'cdh3b3'
default[:hadoop][:deb_version]   = "0.20.2+737-1~lucid-cdh3b3"

# Make sure you define a cluster_size in roles/WHATEVER_cluster.rb
default[:cluster_size] = 5

default[:hadoop][:cluster_reduce_tasks        ] = (node[:cluster_size] * 1.95).to_i
default[:hadoop][:dfs_replication             ] =  3
default[:hadoop][:reduce_parallel_copies      ] =  7
default[:hadoop][:tasktracker_http_threads    ] = 40
default[:hadoop][:jobtracker_handler_count    ] = [node[:cluster_size] * 4, 32].min
default[:hadoop][:namenode_handler_count      ] = [node[:cluster_size] * 4, 32].min
default[:hadoop][:datanode_handler_count      ] = 10

default[:hadoop][:compress_map_output         ] = 'true'
default[:hadoop][:output_compression_type     ] = 'BLOCK'

default[:hadoop][:mapred_userlog_retain_hours ] = 24
default[:hadoop][:mapred_jobtracker_completeuserjobs_maximum ] = 100

# Other recipes can add to this under their own special key, for instance
#  node[:hadoop][:extra_classpaths][:hbase] = '/usr/lib/hbase/hbase.jar:/usr/lib/hbase/lib/zookeeper.jar:/usr/lib/hbase/conf'
#
default[:hadoop][:extra_classpaths]  = { }

# uses /etc/default/hadoop-0.20 to set the hadoop daemon's heapsize
default[:hadoop][:hadoop_daemon_heapsize]       = 1500

#
# fs.inmemory.size.mb  # default XX
#

default[:groups]['hadoop'    ][:gid] = 300
default[:groups]['supergroup'][:gid] = 301
default[:groups]['hdfs'      ][:gid] = 302
default[:groups]['mapred'    ][:gid] = 303

#
# For ebs-backed volumes (or in general, machines with small or slow root
# volumes), you may wish to exclude the root volume from consideration
#
default[:hadoop][:use_root_as_scratch_vol]    = true
default[:hadoop][:use_root_as_persistent_vol] = false

# Extra directories for the Namenode metadata to persist to, for example an
# off-cluster NFS path (only necessary to use if you have a physical cluster)
set[:hadoop][:extra_nn_metadata_path] = nil

# Other hadoop settings
default[:hadoop][:max_balancer_bandwidth]     = 1048576  # bytes per second -- 1MB/s by default

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
  when 'm1.small'   then { :max_map_tasks =>  2, :max_reduce_tasks => 1, :java_child_opts =>  '-Xmx870m',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 160, }
  when 'c1.medium'  then { :max_map_tasks =>  3, :max_reduce_tasks => 2, :java_child_opts =>  '-Xmx870m',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 10, :io_sort_mb => 160, }
  when 'm1.large'   then { :max_map_tasks =>  3, :max_reduce_tasks => 2, :java_child_opts => '-Xmx2432m -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit =>  7471104, :io_sort_factor => 25, :io_sort_mb => 256, }
  when 'c1.xlarge'  then { :max_map_tasks => 10, :max_reduce_tasks => 4, :java_child_opts =>  '-Xmx870m',                                                    :java_child_ulimit =>  2227200, :io_sort_factor => 20, :io_sort_mb => 160, }
  when 'm1.xlarge'  then { :max_map_tasks =>  6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx1920m -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit =>  5898240, :io_sort_factor => 25, :io_sort_mb => 256, }
  when 'm2.xlarge'  then { :max_map_tasks =>  4, :max_reduce_tasks => 2, :java_child_opts => '-Xmx4531m -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 32, :io_sort_mb => 256, }
  when 'm2.2xlarge' then { :max_map_tasks =>  6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 32, :io_sort_mb => 256, }
  when 'm2.4xlarge' then { :max_map_tasks => 12, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m -XX:+UseCompressedOops -XX:MaxNewSize=200m -server', :java_child_ulimit => 13447987, :io_sort_factor => 40, :io_sort_mb => 256, }
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

hadoop_performance_settings[:local_disks]=[]
[ [ '/mnt',  'block_device_mapping_ephemeral0'],
  [ '/mnt2', 'block_device_mapping_ephemeral1'],
  [ '/mnt3', 'block_device_mapping_ephemeral2'],
  [ '/mnt4', 'block_device_mapping_ephemeral3'],
].each do |mnt, ephemeral|
  dev_str = node[:ec2][ephemeral] or next
  # sometimes ohai leaves the /dev/ off.
  dev_str = '/dev/'+dev_str unless dev_str =~ %r{^/dev/}
  hadoop_performance_settings[:local_disks] << [mnt, dev_str]
end
Chef::Log.info(["Hadoop mapreduce tuning", hadoop_performance_settings].inspect)

hadoop_performance_settings.each{|k,v| set[:hadoop][k] = v }

# You may wish to set the following to the same as your HDFS block size, esp if
# you're seeing issues with s3:// turning 1TB files into 30_000+ map tasks
default[:hadoop][:min_split_size] = (128 * 1024 * 1024)
# default[:hadoop][:s3_block_size]  = (128 * 1024 * 1024)
# default[:hadoop][:dfs_block_size] = (128 * 1024 * 1024)
