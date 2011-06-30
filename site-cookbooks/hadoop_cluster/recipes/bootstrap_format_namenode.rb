#
# Cookbook Name:: hadoop
# Recipe::        worker
#
# Copyright 2010, Infochimps, Inc
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
# Format Namenode
#
execute 'format_namenode **REMOVE FROM RUNLIST ON SUCCESSFUL BOOTSTRAP**' do
  command %Q{yes 'Y' | hadoop namenode -format ; true}
  user 'hdfs'
  creates '/mnt/hadoop/hdfs/name/current/VERSION'
  creates '/mnt/hadoop/hdfs/name/current/fsimage'
  notifies  :restart, resources(:service => "#{node[:hadoop][:hadoop_handle]}-namenode")
end
