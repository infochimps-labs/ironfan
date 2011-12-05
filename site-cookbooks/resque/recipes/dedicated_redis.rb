#
# Cookbook Name::       resque
# Description::         Dedicated redis -- a redis solely for this resque
# Recipe::              dedicated_redis
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
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

include_recipe 'redis'
include_recipe 'resque'
include_recipe "runit"

#
# Config
#

# Redis config
template File.join(node[:resque][:conf_dir], 'resque_redis.conf') do
  source        'redis.conf.erb'
  cookbook      'redis'
  mode          "0644"
  action        :create
  variables     :redis => node[:redis].to_hash.merge(node[:resque].to_hash).merge(node[:resque][:redis].to_hash)
end

#
# Daemonize
#

runit_service 'resque_redis' do
  run_restart   false
  run_state     node[:resque][:redis][:run_state]
  cookbook      'redis'
  template_name 'redis_server'
  options       node[:resque]
end

announce(:resque, :redis, :port => node[:resque][:redis][:port])
