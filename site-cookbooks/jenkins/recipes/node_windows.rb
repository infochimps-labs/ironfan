#
# Cookbook Name:: jenkins
# Based on hudson
# Recipe:: node_windows
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

home = node[:jenkins][:node][:home]
url  = node[:jenkins][:server][:url]

jenkins_exe = "#{home}\\jenkins-slave.exe"
service_name = "jenkinsslave"

directory home do
  action :create
end

env "JENKINS_HOME" do
  action :create
  value home
end

env "JENKINS_URL" do
  action :create
  value url
end

template "#{home}/jenkins-slave.xml" do
  source "jenkins-slave.xml"
  variables(:jenkins_home => home,
            :jnlp_url => "#{url}/computer/#{node[:jenkins][:node][:name]}/slave-agent.jnlp")
end

#XXX how-to get this directly from the jenkins server?
remote_file jenkins_exe do
  source "http://maven.dyndns.org/2/com/sun/winsw/winsw/1.8/winsw-1.8-bin.exe"
  not_if { File.exists?(jenkins_exe) }
end

execute "#{jenkins_exe} install" do
  cwd home
  only_if { WMI::Win32_Service.find(:first, :conditions => {:name => service_name}).nil? }
end

service service_name do
  action :nothing
end

jenkins_node node[:jenkins][:node][:name] do
  description  node[:jenkins][:node][:description]
  executors    node[:jenkins][:node][:executors]
  remote_fs    node[:jenkins][:node][:home]
  labels       node[:jenkins][:node][:labels]
  mode         node[:jenkins][:node][:mode]
  launcher     node[:jenkins][:node][:launcher]
  mode         node[:jenkins][:node][:mode]
  availability node[:jenkins][:node][:availability]
end

remote_file "#{home}\\slave.jar" do
  source "#{url}/jnlpJars/slave.jar"
  notifies :restart, resources(:service => service_name), :immediately
end

service service_name do
  action :start
end
