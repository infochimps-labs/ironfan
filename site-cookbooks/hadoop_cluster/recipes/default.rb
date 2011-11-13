#
# Cookbook Name:: hadoop
# Recipe:: default
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
class Chef::Recipe; include HadoopCluster ; end

#
# Cloudera repo
#

# Get the archive key for cloudera package repo
execute "curl -s http://archive.cloudera.com/debian/archive.key | apt-key add -" do
  not_if "apt-key export 'Cloudera Apt Repository' | grep 'BEGIN PGP PUBLIC KEY'"
  notifies :run, "execute[apt-get update]"
end

# # Add cloudera package repo
apt_repository 'cloudera' do
  uri             'http://archive.cloudera.com/debian'
  distro        = node[:hadoop][:cloudera_distro_name] || node[:lsb][:codename]
  distribution    "#{distro}-#{node[:hadoop][:cdh_version]}"
  components      ['contrib']
  action :add
end

# # Dummy apt-get resource, will only be run if the apt repo requires updating
# execute("apt-get update"){ action :nothing }
#
# # Add cloudera package repo
# template "/etc/apt/sources.list.d/cloudera.list" do
#   owner "root"
#   mode "0644"
#   source "sources.list.d-cloudera.list.erb"
#   notifies :run, resources("execute[apt-get update]")
# end

#
# Hadoop users and group
#

group 'hdfs' do gid(node[:groups]['hdfs'][:gid]) ; action [:create] ; end
user  'hdfs' do
  comment    'Hadoop HDFS User'
  uid        302
  group      'hdfs'
  home       "/var/run/hadoop-0.20"
  shell      "/bin/false"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

group 'mapred' do gid(node[:groups]['mapred'][:gid]) ; action [:create] ; end
user  'mapred' do
  comment    'Hadoop Mapred Runner'
  uid        303
  group      'mapred'
  home       "/var/run/hadoop-0.20"
  shell      "/bin/false"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

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
[hadoop_log_dir].each{   |dir| make_hadoop_dir(dir, 'hdfs',   "0755") }

# Locate hadoop logs on scratch dirs
force_link("/var/log/hadoop", hadoop_log_dir )
force_link("/var/log/#{node[:hadoop][:hadoop_handle]}", hadoop_log_dir )

# Make hadoop point to /var/run for pids
make_hadoop_dir('/var/run/hadoop-0.20', 'root', "0775")
force_link('/var/run/hadoop', '/var/run/hadoop-0.20')

#
# Primary hadoop packages
#

hadoop_package nil
hadoop_package "native"
hadoop_package "sbin"
