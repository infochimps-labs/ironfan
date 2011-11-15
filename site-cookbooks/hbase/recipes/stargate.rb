#
# Cookbook Name::       hbase
# Description::         Stargate
# Recipe::              stargate
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

include_recipe "hbase"

cookbook_file "/etc/init.d/hadoop-hbase-stargate" do
  owner "root"
  mode "0744"
  source "hadoop-hbase-stargate"
end

# launch service
service "hadoop-hbase-stargate" do
  action [ :enable, :start ]
  running true
  supports :status => true, :restart => true
end

provide_service ("#{node[:hbase][:cluster_name]}-hbase-stargate")
