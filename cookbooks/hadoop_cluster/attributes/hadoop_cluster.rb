# -*- coding: utf-8 -*-
set[:hadoop][:hadoop_handle] = 'hadoop-0.20'
set[:hadoop][:cdh_version]   = 'cdh3b2'

CLUSTER_SIZE = 31

default[:hadoop][:cluster_reduce_tasks        ] = (CLUSTER_SIZE * 1.95).to_i
default[:hadoop][:dfs_replication             ] =  3
default[:hadoop][:reduce_parallel_copies      ] = CLUSTER_SIZE
default[:hadoop][:jobtracker_handler_count    ] = CLUSTER_SIZE * 2
default[:hadoop][:tasktracker_http_threads    ] = CLUSTER_SIZE * 2
default[:hadoop][:namenode_handler_count      ] = CLUSTER_SIZE * 2
default[:hadoop][:datanode_handler_count      ] = 10

default[:hadoop][:compress_map_output         ] = 'true'
default[:hadoop][:output_compression_type     ] = 'BLOCK'

default[:hadoop][:mapred_userlog_retain_hours ] = 24
default[:hadoop][:mapred_jobtracker_completeuserjobs_maximum ] = 100

#
# fs.inmemory.size.mb  # default XX
#

default[:groups]['hadoop'    ][:gid]          = 300
default[:groups]['supergroup'][:gid]          = 301

#
# For ebs-backed volumes (or in general, machines with small or slow root
# volumes), you may wish to exclude the root volume from consideration
#
default[:hadoop][:use_root_as_scratch_vol]    = true
default[:hadoop][:use_root_as_persistent_vol] = false

# You should give at least one NFS-backed directory for the Namenode metadata to
# persist to.
default[:hadoop][:extra_nn_metadata_path] = '/home/hadoop'

# Other hadoop settings
default[:hadoop][:max_balancer_bandwidth]     = 1048576  # bytes per second -- 1MB/s by default

#
# Tune cluster settings for size of instance
#
# These settings are mostly taken from the cloudera hadoop-ec2 scripts,
# informed by the
#
#   #mappers  M := #Cores
#   #reducers R := #Cores
#   java_Xmx    := 0.75 * (TotalRam / (M+R))
#   ulimit      := 2 * java_Xmx
#
# It assumes EC2 instances with EBS-backed volumes
# If your cluster is heavily used and has many cores/machine (almost always running a full # of maps and reducers) turn down the number of mappers.
# If you typically run from S3 (fully I/O bound) increase the number of maps + reducers moderately.
# In both cases, adjust the memory settings accordingly.
#
# FIXME: The below parameters are calculated for each node.
#   The max_map_tasks and max_reduce_tasks settings apply per-node, no problem here
#   The remaining ones (java_child_opts, io_sort_mb, etc) are applied *per-job*:
#   if you launch your job from an m2.xlarge on a heterogeneous cluster, all of
#   the tasks will kick off with -Xmx2719m and so forth, regardless of the RAM
#   on that machine.
#
hadoop_performance_settings =
  case node[:ec2][:instance_type]
  when 'm1.small'   then { :max_map_tasks => 2, :max_reduce_tasks => 1, :java_child_opts =>  '-Xmx550m', :java_child_ulimit => 2359296, :io_sort_factor => 10, :io_sort_mb => 100, }
  when 'c1.medium'  then { :max_map_tasks => 3, :max_reduce_tasks => 2, :java_child_opts =>  '-Xmx550m', :java_child_ulimit => 2359296, :io_sort_factor => 10, :io_sort_mb => 100, }
  when 'm1.large'   then { :max_map_tasks => 3, :max_reduce_tasks => 2, :java_child_opts => '-Xmx1152m', :java_child_ulimit => 3670016, :io_sort_factor => 25, :io_sort_mb => 250, }
  when 'c1.xlarge'  then { :max_map_tasks => 8, :max_reduce_tasks => 4, :java_child_opts =>  '-Xmx1152m', :java_child_ulimit => 3670016, :io_sort_factor => 20, :io_sort_mb => 150, }
  when 'm1.xlarge'  then { :max_map_tasks => 6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx2048m', :java_child_ulimit => 4194304, :io_sort_factor => 25, :io_sort_mb => 250, }
  when 'm2.xlarge'  then { :max_map_tasks => 3, :max_reduce_tasks => 2, :java_child_opts => '-Xmx2719m', :java_child_ulimit => 5567939, :io_sort_factor => 32, :io_sort_mb => 320, }
  when 'm2.2xlarge' then { :max_map_tasks => 6, :max_reduce_tasks => 3, :java_child_opts => '-Xmx2918m', :java_child_ulimit => 5976883, :io_sort_factor => 32, :io_sort_mb => 320, }
  when 'm2.4xlarge' then { :max_map_tasks => 8, :max_reduce_tasks => 4, :java_child_opts => '-Xmx4378m', :java_child_ulimit => 8965325, :io_sort_factor => 40, :io_sort_mb => 400, }
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
hadoop_performance_settings[:java_child_opts] += ' -XX:+UseCompressedOops -XX:MaxNewSize=200m -server'

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
