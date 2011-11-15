#
# Cookbook Name::       cassandra
# Description::         Base configuration for cassandra
# Recipe::              default
# Author::              Benjamin Black (<b@b3k.us>)
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

include_recipe "java::sun"
include_recipe "thrift"
include_recipe "runit"
include_recipe "mountable_volumes"

%w[ sun-java6-jdk  sun-java6-bin ].each{|pkg| package(pkg) }

%w[ cassandra avro
].each{|pkg| gem_package(pkg){ action :install } }

#%w[ simplejson avro
#].each{|pkg| easy_install_package(pkg){ action :install } }

user "cassandra" do
  uid       '330'
  gid       "nogroup"
  shell     "/bin/false"
  action    :create
  not_if{ node[:etc][:passwd] && node[:etc][:passwd]['cassandra'] }
end


[ "/var/lib/cassandra", "/var/log/cassandra",
  node[:cassandra][:data_file_dirs],
  node[:cassandra][:commitlog_dir],
  node[:cassandra][:saved_caches_dir]
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
end
