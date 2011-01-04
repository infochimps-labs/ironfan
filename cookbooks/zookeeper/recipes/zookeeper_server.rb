#
# Cookbook Name:: zookeeper
# Recipe:: zookeeper_server
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

include_recipe "hadoop_cluster"
include_recipe "zookeeper"

# register with cluster_service_discovery
provide_service ("#{node[:cluster_name]}-zookeeper")

# Install
package "hadoop-zookeeper"
package "hadoop-zookeeper-server"

# launch service
service "hadoop-zookeeper-server" do
  action [ :enable, :start ]
  running true
  supports :status => true, :restart => true
end

#
# Configuration files
#
template_variables = {
  :private_ip             => private_ip_of(node),
}
Chef::Log.debug template_variables.inspect
%w[ zoo.cfg ].each do |conf_file|
  template "/etc/zookeeper/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(template_variables)
    source "#{conf_file}.erb"
  end
end
