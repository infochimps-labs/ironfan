#
# Author:: Benjamin Black (<b@b3k.us>)
# Cookbook Name:: cassandra
# Recipe:: default
#
# Copyright 2010, Benjamin Black
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
include_recipe "thrift"
include_recipe "runit"

gem_package "cassandra" do
  action :install
end

user "cassandra" do
  uid       '330'
  gid       "nogroup"
  shell     "/bin/false"
  action    :create
  not_if{ node[:etc][:passwd] && node[:etc][:passwd]['cassandra'] }
end

[ "/var/lib/cassandra", "/var/log/cassandra",
  node[:cassandra][:data_file_dirs],
  node[:cassandra][:commit_log_dir],
  node[:cassandra][:callout_location],
  node[:cassandra][:staging_file_dir],
].flatten.each do |cassandra_dir|
  directory cassandra_dir do
    owner    "cassandra"
    group    "root"
    mode     "0755"
    action   :create
    recursive true
  end
end

directory "/etc/cassandra" do
  owner     "root"
  group     "root"
  mode      "0755"
  action    :create
  not_if    "test -d /etc/cassandra"
end

template "/etc/cassandra/storage-conf.xml" do
  source    "storage-conf.xml.erb"
  owner     "root"
  group     "root"
  mode      0644
  # notifies  :restart, resources(:service => "cassandra")
end

runit_service "cassandra"

service "cassandra" do
  supports :status => true, :restart => true, :reload => true
  action [ :enable, :start ]
end
