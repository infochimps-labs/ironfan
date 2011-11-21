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

provide_service("#{node[:elasticsearch][:cluster_name]}-data_esnode")

# Tell ElasticSearch where to find its other nodes
provide_service "#{node[:cluster_name]}-elasticsearch"
if node[:elasticsearch][:seeds].nil?
    node[:elasticsearch][:seeds] = all_provider_private_ips("#{node[:cluster_name]}-elasticsearch").sort().map { |ip| ip+':9300' }
end

runit_service "elasticsearch" do
  run_restart   false   # don't automatically start or restart daemons
  options       node[:elasticsearch]
end
