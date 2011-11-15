#
# Cookbook Name::       resque
# Description::         Server
# Recipe::              server
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

#
# Config
#

# Redis config
template File.join(node[:resque][:conf_dir], 'resque_redis.conf') do
  source 'resque_redis.conf.erb'
  mode 0664
  group 'admin'
  action :create
end

# include resque_conf in your scripts
template File.join(node[:resque][:conf_dir], 'resque_conf.rb') do
  source 'resque_conf.rb.erb'
  mode 0664
  group 'admin'
  action :create
end

#
# Daemonize
#

runit_service 'resque_redis' do
  run_restart false
end
provide_service('resque_redis', :port => node[:resque][:queue_port])

runit_service 'resque_dashboard' do
  run_restart false
end
provide_service('resque_dashboard', :port => node[:resque][:dashboard_port])
