#
# Cookbook Name::       zookeeper
# Description::         Base configuration for zookeeper
# Recipe::              default
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2010, Infochimps, Inc.
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
include_recipe "apt"
include_recipe "mountable_volumes"

#
# Add Cloudera Apt Repo
#

# Get the archive key for cloudera package repo
execute "curl -s http://archive.cloudera.com/debian/archive.key | apt-key add -" do
  not_if "apt-key export 'Cloudera Apt Repository' | grep 'BEGIN PGP PUBLIC KEY'"
  notifies :run, "execute[apt-get update]"
end

# Add cloudera package repo
apt_repository 'cloudera' do
  uri             'http://archive.cloudera.com/debian'
  distro        = node[:lsb][:codename]
  distribution    "#{distro}-#{node[:hadoop][:cdh_version]}"
  components      ['contrib']
  key             "http://archive.cloudera.com/debian/archive.key"
  action          :add
end

#
# Install package
#

package "hadoop-zookeeper"

#
# User and Groups
#

group 'zookeeper' do gid 305 ; action [:create] ; end
user 'zookeeper' do
  comment    'Hadoop Zookeeper Daemon'
  uid        305
  group      node[:groups]['zookeeper' ][:gid]
  home       "/var/zookeeper"
  shell      "/bin/false"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

#
# Configuration files
#

directory node[:zookeeper][:data_dir] do
  owner      "zookeeper"
  group      "zookeeper"
  mode       "0755"
  action     :create
  recursive  true
end

directory node[:zookeeper][:log_dir] do
  owner      "zookeeper"
  group      "zookeeper"
  mode       "0755"
  action     :create
  recursive  true
end

#
# Config files
#
zookeeper_server_ips =  all_provider_private_ips("#{node[:zookeeper][:cluster_name]}-zookeeper").sort
myid = zookeeper_server_ips.find_index( private_ip_of node )
template_variables = {
  :zookeeper_server_ips   => zookeeper_server_ips,
  :myid                   => myid,
  :zookeeper_data_dir     => node[:zookeeper][:data_dir],
  :zookeeper_max_client_connections => node[:zookeeper][:max_client_connections],
}
Chef::Log.debug template_variables.inspect

%w[ zoo.cfg log4j.properties].each do |conf_file|
  template "/etc/zookeeper/#{conf_file}" do
    variables(template_variables)
    owner    "root"
    mode     "0644"
    source   "#{conf_file}.erb"
  end
end

template "/var/zookeeper/myid" do
 owner "zookeeper"
 mode "0644"
 variables(template_variables)
 source "myid.erb"
end
