# -*- coding: utf-8 -*-
default[:hadoop][:hadoop_handle] = 'hadoop-0.20'
set[:hadoop][:cdh_version]   = 'cdh3b1'

default[:hadoop][:cluster_reduce_tasks]       = 57
default[:hadoop][:dfs_replication]            = 3
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
set[:hadoop][:extra_nn_metadata_path] = '/home/hadoop'


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
hadoop_performance_settings =
  case node[:ec2][:instance_type]
  when 'm1.small'   then { :max_map_tasks => 2, :max_reduce_tasks => 1, :java_child_opts =>  '-Xmx550m', :java_child_ulimit => 1126400, :io_sort_factor => 10, :io_sort_mb => 100, }
  when 'c1.medium'  then { :max_map_tasks => 3, :max_reduce_tasks => 2, :java_child_opts =>  '-Xmx550m', :java_child_ulimit => 1126400, :io_sort_factor => 10, :io_sort_mb => 100, }
  when 'm1.large'   then { :max_map_tasks => 3, :max_reduce_tasks => 2, :java_child_opts => '-Xmx1152m', :java_child_ulimit => 2359296, :io_sort_factor => 25, :io_sort_mb => 250, }
  #when 'c1.xlarge' then { :max_map_tasks => 8, :max_reduce_tasks => 4, :java_child_opts =>  '-Xmx550m', :java_child_ulimit => 1126400, :io_sort_factor => 10, :io_sort_mb => 100, }
  when 'c1.xlarge'  then { :max_map_tasks => 8, :max_reduce_tasks => 4, :java_child_opts =>  '-Xmx550m', :java_child_ulimit => 1126400, :io_sort_factor => 20, :io_sort_mb => 200, }
  when 'm1.xlarge'  then { :max_map_tasks => 6, :max_reduce_tasks => 4, :java_child_opts => '-Xmx1152m', :java_child_ulimit => 2359296, :io_sort_factor => 25, :io_sort_mb => 250, }
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
Chef::Log.info(hadoop_performance_settings.inspect)

hadoop_performance_settings.each{|k,v| set[:hadoop][k] = v }

#
# # FIXME -- integrate into the config files
#
# default[:hadoop][:io_sort_factor]  = 10
# default[:hadoop][:io_sort_mb]      = 100            # set to 10 * io.sort.factor; make sure -Xmx above is 2x or more
# default[:hadoop][:io_sort_record_pct]       = 0.05  # default 0.05; rec. 16(16+avg_rec_sz_in_bytes)
#
# default[:hadoop][:namenode_handler_count]   = 16    # default 5; rec. 64
# default[:hadoop][:jobtracker_handler_count] = 16    # default 5; rec. 64    # The number of server threads for the JobTracker. This should be roughly 4% of the number of tasktracker nodes.
# default[:hadoop][:datanode_handler_count]   = 6     # default 3; rec. 8-10
#
# default[:hadoop][:tasktracker_http_threads] = 40    # default 66; rec 40
#
# default[:hadoop][:reduce_parallel_copies]
#
# fs.inmemory.size.mb  # default XX
#

# # http://www.cloudera.com/blog/2009/03/configuration-parameters-what-can-you-just-ignore/
# #
# # If there is more RAM available than is consumed by task instances, set
# # io.sort.factor to 25 or 32 (up from 10). io.sort.mb should be 10 *
# # io.sort.factor. Don’t forget, multiply io.sort.mb by the number of concurrent
# # tasks to determine how much RAM you’re actually allocating here, to prevent
# # swapping. (So 10 task instances with io.sort.mb = 320 means you’re actually
# # allocating 3.2 GB of RAM for sorting, up from 1.0 GB.) An open ticket on the
# # Hadoop bug tracking database suggests making the default value here 100. This
# # would likely result in a lower per-stream cache size than 10 MB.
# #
# # io.file.buffer.size – this is one of the more “magic” parameters. You can set
# # this to 65536 and leave it there. (I’ve profiled this in a bunch of scenarios;
# # this seems to be the sweet spot.)
# #
# # If the NameNode and JobTracker are on big hardware, set
# # dfs.namenode.handler.count to 64 and same with
# # mapred.job.tracker.handler.count. If you’ve got more than 64 GB of RAM in this
# # machine, you can double it again.
# #
# # dfs.datanode.handler.count defaults to 3 and could be set a bit higher. (Maybe
# # 8 or 10.) More than this takes up memory that could be devoted to running
# # MapReduce tasks, and I don’t know that it gives you any more performance. (An
# # increased number of HDFS clients implies an increased number of DataNodes to
# # handle the load.)
# #
# # mapred.child.ulimit should be 2–3x higher than the heap size specified in
# # mapred.child.java.opts and left there to prevent runaway child task memory
# # consumption.
# #
# # Setting tasktracker.http.threads higher than 40 will deprive individual tasks
# # of RAM, and won’t see a positive impact on shuffle performance until your
# # cluster is approaching 100 nodes or more.
# #
# # the magic number for io.sort.record.percent is 16/(16 + average record size in
# # bytes). You can calculate the average record size by simply looking at the job
# # counters and dividing map output bytes by map output records.
# #    eg. 550GB / 11B records = 50b => 16/(16+50) = 24%
#
# # Note that the HADOOP_HEAPSIZE sets heap for the daemons (namenode, etc) and not the tasks.

