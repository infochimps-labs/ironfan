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

include_recipe 'redis::client'
include_recipe 'runit'

#
# Install
#

gem_package 'thin'
gem_package 'rack'
gem_package 'resque'
gem_package 'redis'
gem_package 'redis-namespace'
gem_package 'yajl-ruby'

daemon_user('resque')

standard_dirs('resque') do
  directories :home_dir, :log_dir, :tmp_dir, :data_dir, :journal_dir, :conf_dir
end

#
# Config
#

# include resque_conf in your scripts
template File.join(node[:resque][:conf_dir], 'resque_conf.rb') do
  source        'resque_conf.rb.erb'
  mode          "0644"
  action        :create
end

#
# Daemonize
#

runit_service 'resque_dashboard' do
  run_state     node[:resque][:dashboard][:run_state]
  options       node[:resque]
end

announce(:resque, :dashboard, :port => node[:resque][:dashboard_port])
