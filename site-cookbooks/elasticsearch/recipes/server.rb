#
# Cookbook Name::       elasticsearch
# Description::         Server
# Recipe::              server
# Author::              GoTime, modifications by Infochimps
#
# Copyright 2011, GoTime, modifications by Infochimps
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

include_recipe "runit"

#
# Locations
#

volume_dirs('elasticsearch.data') do
  type          :local
  selects       :single
  mode          "0700"
end

volume_dirs('elasticsearch.work') do
  type          :local
  selects       :single
  mode          "0700"
end

# FIXME: Is this supposed to be handled by volume_dirs?
directory "#{node[:elasticsearch][:data_root]}" do
  owner         "elasticsearch"
  group         "elasticsearch"
  mode          0755
end

#
# Service
#

runit_service "elasticsearch" do
  run_restart   false   # don't automatically start or restart daemons
  run_state     node[:elasticsearch][:server][:run_state]
  options       node[:elasticsearch]
end

# TODO: split httpnode and datanode into separate components
announce(:elasticsearch, :datanode)
announce(:elasticsearch, :httpnode)

# Tell ElasticSearch where to find its other nodes
if node[:elasticsearch][:seeds].nil?
  es_servers = discover_all(:elasticsearch, :datanode)

  # FIXME: use the port from the component
  node[:elasticsearch][:seeds] = es_servers.map{|svr| "#{svr.private_ip}:#{node[:elasticsearch][:api_port] }" }
end
