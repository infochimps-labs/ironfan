
include_recipe 'cluster_chef'

#
# Register dashboard
#

hadoop_services.each do |component|
  next unless node[:hadoop][component] && node[:hadoop][component][:dash_port]
  hsh = { :addr => node[:fqdn] }.merge(node[:hadoop][component])
  add_dashboard_link("hadoop.#{component}", hsh)
end

#
# Drop in our mini-dashboard
#

cluster_chef_dashboard(:hadoop_cluster) do

  summary_keys = %w[
  ==Daemons
    namenode.addr   namenode.port jobtracker.addr jobtracker.port
    public_ip fqdn cloud.private_ips cloud.public_ips
    ----
       namenode.run_state
    secondarynn.run_state
     jobtracker.run_state
       datanode.run_state
    tasktracker.run_state
  ==Tuning
    max_map_tasks max_reduce_tasks
    java_child_opts java_child_ulimit io_sort_factor io_sort_mb
    cpu.total memory.total ec2.instance_type
    ----
       namenode.handler_count
     jobtracker.handler_count
       datanode.handler_count
    tasktracker.http_threads
         reducer_parallel_copies
    ----
       namenode.java_heap_size_max
    secondarynn.java_heap_size_max
     jobtracker.java_heap_size_max
       datanode.java_heap_size_max
    tasktracker.java_heap_size_max
  ==MapReduce
    compress_output
    compress_output_type
    compress_output_codec
    compress_mapout
    compress_mapout_codec
  ==HDFS
    min_split_size s3_block_size hdfs_block_size dfs_replication
  ==Install
    home_dir pid_dir tmp_dir log_dir
       namenode.data_dirs
    secondarynn.data_dirs
       datanode.data_dirs
    tasktracker.scratch_dirs
    ----
    apt.cloudera.release_name deb_version
  ]

  variables     node[:hadoop].merge(:summary_keys => summary_keys)
end
