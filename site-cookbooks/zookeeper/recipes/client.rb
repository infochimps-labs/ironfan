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
template_variables = {
  :zookeeper_server_ips   => all_provider_private_ips("#{node[:cluster_name]}-zookeeper").sort,
  :zookeeper_data_dir     => node[:zookeeper][:data_dir],
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
