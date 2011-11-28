#
# Cookbook Name::       statsd
# Description::         Server
# Recipe::              server
# Author::              Nathaniel Eliot - Infochimps, Inc
#
# Copyright 2011, Nathaniel Eliot - Infochimps, Inc
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
include_recipe "cluster_chef"
include_recipe "statsd::default"

daemon_user(:statsd)

standard_directories('statsd') do
  directories   :conf_dir, :log_dir, :pid_dir
end

runit_service "statsd" do
  options       node[:statsd]
  action        node[:statsd][:run_state]
end

provide_service("#{node[:cluster_name]}-statsd", :port => node[:statsd][:port])

git node[:statsd][:home_dir] do
  repository    node[:statsd][:git_repo]
  reference     "master"
  action        :checkout
  notifies      :restart, "service[statsd]", :delayed if startable?(node[:statsd])
end

template "#{node[:statsd][:home_dir]}/baseConfig.js" do
  source        "baseConfig.js.erb"
  mode          "0755"
  variables     :statsd => node[:statsd]
  notifies      :restart, "service[statsd]", :delayed if startable?(node[:statsd])
end
