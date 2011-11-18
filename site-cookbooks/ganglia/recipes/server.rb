#
# Cookbook Name::       ganglia
# Description::         Server
# Recipe::              server
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2011, Chris Howe - Infochimps, Inc
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

package "ganglia-webfrontend"
package "gmetad"

service "gmetad" do
  enabled true
end

cluster_nodes = {}
search(:node, '*:*') do |node|
  next unless   node['ganglia']['cluster_name']
  cluster_nodes[node['ganglia']['cluster_name']] ||= []
  cluster_nodes[node['ganglia']['cluster_name']] << node['fqdn'].split('.').first
end

template "#{node[:ganglia][:conf_dir]}/gmetad.conf" do
  source        "gmetad.conf.erb"
  backup        false
  owner         "ganglia"
  group         "ganglia"
  mode          "0644"
  variables(:cluster_nodes => cluster_nodes, :clusters => search(:ganglia_clusters, "*:*"))
  notifies :restart, resources(:service => "gmetad")
end

directory "#{node[:ganglia][:home_dir]}/rrds" do
  owner         "ganglia"
  group         "ganglia"
end
