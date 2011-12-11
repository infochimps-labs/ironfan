#
# Cookbook Name::       zookeeper
# Description::         Installs Zookeeper server, sets up and starts service
# Recipe::              server
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

include_recipe 'runit'
include_recipe 'metachef'
include_recipe "zookeeper::default"

# Install
package "hadoop-zookeeper-server"

daemon_user(:zookeeper) do
  home          node[:zookeeper][:data_dir]
end

standard_dirs('zookeeper.server') do
  directories   :data_dir
end

kill_old_service('hadoop-zookeeper-server'){ pattern 'zookeeper' ; not_if{ File.exists?("/etc/init.d/hadoop-zookeeper-server") } }

announce(:zookeeper, :server)

runit_service "zookeeper" do
  run_state     node[:zookeeper][:server][:run_state]
  options       node[:zookeeper]
end
