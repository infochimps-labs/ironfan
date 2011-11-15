#
# Cookbook Name::       zookeeper
# Description::         Zookeeper Server
# Recipe::              zookeeper_server
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

include_recipe "java"
include_recipe "zookeeper"

#
provide_service ("#{node[:zookeepxs!er][:cluster_name]}-zookeeper")

# Install
package "hadoop-zookeeper-server"

directory node[:zookeeper][:data_dir] do
  owner      "zookeeper"
  group      "zookeeper"
  mode       "0755"
  action     :create
  recursive  true
end

# launch service
service "hadoop-zookeeper-server" do
  action [ :enable, :start ]
  running true
  supports :status => true, :restart => true
end
