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

group("redis"){ gid 335 }
user "redis" do
  comment   "Redis-server runner"
  uid       335
  gid       "redis"
  shell     "/bin/false"
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

# These are included explicitly until I can untangle the hellscape of
# dependencies on redis in the rest of our recipes
include_recipe 'redis::install_from_package'
include_recipe 'redis::server'
