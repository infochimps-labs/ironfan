#
# Cookbook Name::       hadoop_cluster
# Description::         Secondarynn
# Recipe::              secondarynn
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2009, Opscode, Inc.
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

# Install
hadoop_package "secondarynamenode"

# Set up service
runit_service "hadoop_secondarynn" do
  options       Mash.new(:service_name => 'secondarynamenode').merge(node[:hadoop]).merge(node[:hadoop][:secondarynn])
  action        node[:hadoop][:secondarynn][:run_state]
end

provide_service ("#{node[:cluster_name]}-secondarynn")
