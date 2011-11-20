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

%w[
  thin rack resque redis redis-namespace yajl-ruby
].each{|gem_name| gem_package gem_name }

directory ::File.dirname(node[:resque][:home_dir]) do
  owner     'root'
  group     'root'
  mode      "0775"
  recursive true
  action    :create
end

#
# User
#
group 'resque' do gid 336 ; action [:create] ; end
user 'resque' do
  comment       'Resque queue user'
  uid           336
  group         'resque'
  home          node[:resque][:home_dir]
  shell         "/bin/false"
  password      nil
  supports      :manage_home => true
  action        [:create, :manage]
end

#
# Directories
#
[ :log_dir, :tmp_dir, :data_dir, :journal_dir, :conf_dir ].each do |dirname|
  directory node[:resque][dirname] do
    owner       node[:resque][:user]
    group       node[:resque][:group]
    mode        "0775"
    recursive   true
    action      :create
  end
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
  run_restart false
end
provide_service('resque_dashboard', :port => node[:resque][:dashboard_port])
