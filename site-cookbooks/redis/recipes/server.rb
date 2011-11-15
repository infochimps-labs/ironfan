#
# Cookbook Name::       redis
# Description::         Server
# Recipe::              server
# Author::              Benjamin Black
#
# Copyright 2011, Benjamin Black
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

group("redis"){ gid 335 }
user "redis" do
  comment   "Redis-server runner"
  uid       335
  gid       "redis"
  shell     "/bin/false"
end

template "/etc/init.d/redis-server" do
  source "redis-server-init-d.erb"
  owner "root"
  group "root"
  mode 0744
end

runit_service "redis-server" do
  action :enable
end

template "/etc/redis/redis.conf" do
  source "redis.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies(:restart, resources(:service => "redis-server")) unless node[:platform_version].to_f < 9.0
end

provide_service("#{node[:cluster_name]}-redis", :port => node[:redis][:port] )
