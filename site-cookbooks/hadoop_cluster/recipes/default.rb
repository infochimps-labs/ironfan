#
# Cookbook Name::       hadoop_cluster
# Description::         Base configuration for hadoop_cluster
# Recipe::              default
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2009, Opscode, Inc.
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

include_recipe "java::sun"
include_recipe "runit"
include_recipe "apt"
include_recipe "mountable_volumes"
class Chef::Recipe; include HadoopCluster ; end

include_recipe "hadoop_cluster::add_cloudera_repo"

#
# Hadoop users and group
#

daemon_user(:hadoop) do
  user         :hdfs
end

daemon_user(:hadoop) do
  user         :mapred
end

# group 'hdfs' do gid(node[:groups]['hdfs'][:gid]) ; action [:create] ; end
# user  'hdfs' do
#   comment    'Hadoop HDFS User'
#   uid        302
#   group      'hdfs'
#   home       "/var/run/hadoop-0.20"
#   shell      "/bin/false"
#   password   nil
#   supports   :manage_home => false
#   action     [:create, :manage]
# end
#
# group 'mapred' do gid(node[:groups]['mapred'][:gid]) ; action [:create] ; end
# user  'mapred' do
#   comment    'Hadoop Mapred Runner'
#   uid        303
#   group      'mapred'
#   home       "/var/run/hadoop-0.20"
#   shell      "/bin/false"
#   password   nil
#   supports   :manage_home => false
#   action     [:create, :manage]
# end
#

group 'hadoop' do
  group_name 'hadoop'
  gid         node[:groups]['hadoop'][:gid]
  action      [:create, :manage]
  members     ['hdfs', 'mapred']
end

# Create the group hadoop uses to mean 'can act as filesystem root'
group 'supergroup' do
  group_name 'supergroup'
  gid        node[:groups]['supergroup'][:gid]
  action     [:create]
  not_if     "grep -q supergroup /etc/group"
end

#
# Hadoop directories
#

# Important: In CDH3 Beta 3, the mapred.system.dir directory must be located inside a directory that is owned by mapred. For example, if mapred.system.dir is specified as /mapred/system, then /mapred must be owned by mapred. Don't, for example, specify /mrsystem as mapred.system.dir because you don't want / owned by mapred.
#
# Directory             Owner           Permissions
# dfs.name.dir          hdfs:hadoop     drwx------
# dfs.data.dir          hdfs:hadoop     drwxr-xr-x
# mapred.local.dir      mapred:hadoop   drwxr-xr-x
# mapred.system.dir     mapred:hadoop   drwxr-xr-x

#
# Physical directories for HDFS files and metadata
# (dfs_name_dirs/dfs_2nn_dirs are in namenode/secondarynamenode recipes)
dfs_data_dirs.each{      |dir| make_hadoop_dir(dir, 'hdfs',   "0700") }
mapred_local_dirs.each{  |dir| make_hadoop_dir(dir, 'mapred', "0755") }
[hadoop_tmp_dir].each{   |dir| make_hadoop_dir(dir, 'hdfs',   "0777") }
[hadoop_log_dir].each{   |dir| make_hadoop_dir(dir, 'hdfs',   "0775") }

# Locate hadoop logs on scratch dirs
force_link("/var/log/hadoop", hadoop_log_dir )
force_link("/var/log/#{node[:hadoop][:handle]}", hadoop_log_dir )

# Make hadoop point to /var/run for pids
make_hadoop_dir('/var/run/hadoop-0.20', 'root', "0775")
force_link('/var/run/hadoop', '/var/run/hadoop-0.20')

#
# Primary hadoop packages
#

hadoop_package nil
hadoop_package "native"
hadoop_package "sbin"
