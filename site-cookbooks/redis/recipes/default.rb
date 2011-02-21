#
# Author:: Benjamin Black (<b@b3k.us>)
# Cookbook Name:: redis
# Recipe:: default
#
# Copyright 2009, Benjamin Black
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

redis_package = "redis-server"

group("redis"){ gid 335 }
user "redis" do
  comment   "Redis-server runner"
  uid       335
  gid       "redis"
  shell     "/bin/false"
end

unless node[:platform_version].to_f < 9.0
  package redis_package do
    action :install
  end
end

directory "/var/log/redis" do
  owner     "redis"
  group     "redis"
  mode      "0755"
  action    :create
end

directory node[:redis][:dbdir] do
  owner     "redis"
  group     "redis"
  mode      "0755"
  action    :create
  recursive true
end

directory "/etc/redis" do
  owner     "root"
  group     "root"
  mode      "0755"
  action    :create
end

template "/etc/init.d/redis-server" do
  source "redis-server-init-d.erb"
  owner "root"
  group "root"
  mode 0744
end

service redis_package do
  action :enable
end

template "/etc/redis/redis.conf" do
  source "redis.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies(:restart, resources(:service => redis_package)) unless node[:platform_version].to_f < 9.0
end
