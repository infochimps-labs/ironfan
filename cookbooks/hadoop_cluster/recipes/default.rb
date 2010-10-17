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

include_recipe "java"
class Chef::Recipe; include HadoopCluster ; end

execute "apt-get update" do
  action :nothing
end

# Add cloudera package repo
template "/etc/apt/sources.list.d/cloudera.list" do
  owner "root"
  mode "0644"
  source "apt-sources-cloudera.list.erb"
  notifies :run, resources("execute[apt-get update]")
end
# Get the archive key for cloudera package repo
execute "curl -s http://archive.cloudera.com/debian/archive.key | apt-key add -" do
  not_if "apt-key export 'Cloudera Apt Repository' | grep 'BEGIN PGP PUBLIC KEY'"
  notifies :run, resources("execute[apt-get update]"), :immediately
end

# Hadoop user and group
group 'hadoop' do
  group_name 'hadoop'
  gid         node[:groups]['hadoop'][:gid]
  action      [:create, :manage]
end

user 'hadoop' do
  comment    'Hadoop User'
  uid        300
  group      'hadoop'
  home       "/var/run/hadoop-0.20"
  shell      "/bin/false"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

# Create the group hadoop uses to mean 'can act as filesystem root'
group 'supergroup' do
  group_name 'supergroup'
  gid        node[:groups]['supergroup'][:gid]
  action     [:create]
end

#
# Hadoop packages
#
package "#{node[:hadoop][:hadoop_handle]}" do
  version "0.20.2+320-1~lucid-cdh3b2"
end

package "#{node[:hadoop][:hadoop_handle]}-native" do
  version "0.20.2+320-1~lucid-cdh3b2"
end
