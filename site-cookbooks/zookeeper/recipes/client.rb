#
# Cookbook Name:: zookeeper
# Recipe:: default
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

include_recipe "java"
include_recipe "zookeeper"

#
# Configuration files
#
zookeeper_server_ips =  all_provider_private_ips("#{node[:zookeeper][:cluster_name]}-zookeeper").sort
# FIXME: This doesn't seem stable. I think we're better off using the IP address or something(?)
myid = zookeeper_server_ips.find_index( private_ip_of node )
template_variables = {
  :zookeeper_server_ips   => zookeeper_server_ips,
  :myid                   => myid,
  :zookeeper_data_dir     => node[:zookeeper][:data_dir],
}

directory node[:zookeeper][:log_dir] do
  owner      "zookeeper"
  group      "zookeeper"
  mode       "0755"
  action     :create
  recursive  true
end

Chef::Log.debug template_variables.inspect
%w[ zoo.cfg log4j.properties ].each do |conf_file|
  template "/etc/zookeeper/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(template_variables)
    source "#{conf_file}.erb"
  end
end
