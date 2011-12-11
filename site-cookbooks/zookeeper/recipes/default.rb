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

include_recipe "apt"
include_recipe "volumes"
include_recipe "metachef"
include_recipe "java" ; complain_if_not_sun_java(:cassandra)

include_recipe "zookeeper::add_cloudera_repo"

#
# Install package
#

package "hadoop-zookeeper"

#
# Configuration files
#

standard_dirs('zookeeper.server') do
  directories   :conf_dir, :log_dir
end

#
# Config files
#
zookeeper_server_ips = discover_all(:zookeeper, :server).map(&:private_ip).sort

myid = zookeeper_server_ips.find_index( private_ip_of node )
template_variables = {
  :zookeeper              => node[:zookeeper],
  :zookeeper_server_ips   => zookeeper_server_ips,
  :myid                   => myid,
}

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
