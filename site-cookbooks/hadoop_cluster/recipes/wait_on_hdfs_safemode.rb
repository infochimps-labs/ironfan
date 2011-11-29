#
# Cookbook Name::       hadoop_cluster
# Description::         Wait on HDFS Safemode -- insert between cookbooks to ensure HDFS is available
# Recipe::              wait_on_hdfs_safemode
# Author::              Philip (flip) Kromer - Infochimps, Inc
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

#
# This recipe checks if the HDFS is out of safenode: enough datanodes have come
# online as to allow HDFS filesystem operations
#
# This will spin indefinitely, so be careful where you put it in your
# run_list order.
#

execute 'wait until the HDFS is out of safemode' do
  only_if       "service hadoop_namenode status"
  user          'hdfs'
  command       %Q{hadoop dfsadmin -safemode wait}

  ignore_failure true
end
