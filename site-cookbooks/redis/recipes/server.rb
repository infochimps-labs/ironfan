#
# Cookbook Name::       redis
# Description::         Redis server with runit service
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

include_recipe 'runit'
include_recipe 'metachef'
include_recipe 'redis::default'

daemon_user(:redis) do
  home          node[:redis][:data_dir]
end

standard_dirs('redis.server') do
  directories   :conf_dir, :log_dir, :data_dir
end

kill_old_service('redis-server'){ pattern 'gmond' ; not_if{ File.exists?("/etc/init.d/redis-server") } }

runit_service "redis_server" do
  run_state     node[:redis][:server][:run_state]
  options       node[:redis]
end

announce(:redis, :server,
  :port => node[:redis][:server][:port])
