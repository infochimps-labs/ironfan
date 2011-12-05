#
# Cookbook Name::       hadoop_cluster
# Description::         Simple Dashboard
# Recipe::              simple_dashboard
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'dashpot'

#
# Register dashboard
#

hadoop_services.each do |component|
  next unless node[:hadoop][component] && node[:hadoop][component][:dash_port]
  hsh = { "addr" => private_ip_of(node) }.merge(node[:hadoop][component])
  add_dashboard_link("hadoop.#{component}", hsh)
end

#
# Drop in our mini-dashboard
#

dashpot_dashboard(:hadoop_cluster) do
  summary_keys = %w[
  ==Daemons
    hadoop.namenode.addr   hadoop.namenode.port hadoop.jobtracker.addr hadoop.jobtracker.port
    public_ip fqdn cloud.private_ips cloud.public_ips
    ----
       hadoop.namenode.run_state
    hadoop.secondarynn.run_state
     hadoop.jobtracker.run_state
       hadoop.datanode.run_state
    hadoop.tasktracker.run_state
  ==Tuning
    hadoop.max_map_tasks hadoop.max_reduce_tasks
    hadoop.java_child_opts hadoop.java_child_ulimit hadoop.io_sort_factor hadoop.io_sort_mb
    cpu.total memory.total ec2.instance_type
    ----
       hadoop.namenode.handler_count
     hadoop.jobtracker.handler_count
       hadoop.datanode.handler_count
    hadoop.tasktracker.http_threads
         hadoop.reducer_parallel_copies
    ----
       hadoop.namenode.java_heap_size_max
    hadoop.secondarynn.java_heap_size_max
     hadoop.jobtracker.java_heap_size_max
       hadoop.datanode.java_heap_size_max
    hadoop.tasktracker.java_heap_size_max
  ==MapReduce
    hadoop.compress_output
    hadoop.compress_output_type
    hadoop.compress_output_codec
    hadoop.compress_mapout
    hadoop.compress_mapout_codec
  ==HDFS
    hadoop.min_split_size hadoop.s3_block_size hadoop.hdfs_block_size hadoop.dfs_replication
  ==Install
    hadoop.home_dir hadoop.pid_dir hadoop.tmp_dir hadoop.log_dir
       hadoop.namenode.data_dirs
    hadoop.secondarynn.data_dirs
       hadoop.datanode.data_dirs
    hadoop.tasktracker.scratch_dirs
    ----
    apt.cloudera.release_name hadoop.deb_version
  ]

  action        :create
  variables     Mash.new(:summary_keys => summary_keys).merge(node[:hadoop])
end
