#
# Cookbook Name::       hadoop_cluster
# Description::         Pseudo Distributed
# Recipe::              pseudo_distributed
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

#
# This installs packages for running hadoop in 'pseudo-distributed' mode, which
# some use for testing purposes.
#
# I haven't really tested pseudo-distributed mode out with the larger
# scripts, so ymmv.
#

include_recipe "hadoop_cluster"
include_recipe "hadoop_cluster::cluster_conf"

package "#{node[:hadoop][:hadoop_handle]}-conf-pseudo" do
  if node[:hadoop][:deb_version] != 'current'
    version node[:hadoop][:deb_version]
  end
end

%w{namenode secondarynamenode datanode jobtracker tasktracker}.each do |d|
  service "#{node[:hadoop][:hadoop_handle]}-#{d}" do
    action [ :start, :enable ]
  end
end

