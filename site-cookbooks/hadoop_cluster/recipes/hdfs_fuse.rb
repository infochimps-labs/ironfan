#
# Cookbook Name::       hadoop_cluster
# Description::         Installs Hadoop HDFS Fuse service (regular filesystem access to HDFS files)
# Recipe::              hdfs_fuse
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
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

class Chef::Recipe; include HadoopCluster ; end

hadoop_package "fuse"
include_recipe "runit"

directory "/hdfs" do
  owner         "hdfs"
  group         "supergroup"
  mode          "0755"
  action        :create
  recursive      true
end

execute "add fuse module to kernel" do
  command %Q{/sbin/modprobe fuse; true}
end

execute 'fix fuse configuration to allow hadoop' do
  command       %Q{sed -i -e 's|#user_allow_other|user_allow_other|' /etc/fuse.conf && chown hdfs:hadoop /etc/fuse.conf}
  user          'root'
  not_if        "egrep '^user_allow_other' /etc/fuse.conf"
end

runit_service "hdfs_fuse" do
  run_state     node[:hadoop][:hdfs_fuse][:run_state]
  finish_script true
  options       node[:hadoop]
end
