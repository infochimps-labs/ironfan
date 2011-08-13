#
# Cookbook Name:: jenkins
# Based on hudson
# Recipe:: node_jnlp
#
# Author:: Doug MacEachern <dougm@vmware.com>
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2010, VMware, Inc.
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

service_name = "jenkins-slave"
slave_jar = "#{node[:jenkins][:node][:home]}/slave.jar"

group node[:jenkins][:node][:user] do
end

user node[:jenkins][:node][:user] do
  comment "Jenkins CI node (jnlp)"
  gid node[:jenkins][:node][:user]
  home node[:jenkins][:node][:home]
end

directory node[:jenkins][:node][:home] do
  action :create
  owner node[:jenkins][:node][:user]
  group node[:jenkins][:node][:user]
end

jenkins_node node[:jenkins][:node][:name] do
  description  node[:jenkins][:node][:description]
  executors    node[:jenkins][:node][:executors]
  remote_fs    node[:jenkins][:node][:home]
  labels       node[:jenkins][:node][:labels]
  mode         node[:jenkins][:node][:mode]
  launcher     "jnlp"
  mode         node[:jenkins][:node][:mode]
  availability node[:jenkins][:node][:availability]
end

remote_file slave_jar do
  source "#{node[:jenkins][:server][:url]}/jnlpJars/slave.jar"
  owner node[:jenkins][:node][:user]
  #only restart if slave.jar is updated
  if ::File.exists?(slave_jar)
    notifies :restart, "service[#{service_name}]", :immediately
  end
end

runit_service service_name
