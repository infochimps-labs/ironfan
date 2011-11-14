#
# Cookbook Name::       statsd
# Recipe::              default
# Author::              Nathaniel Eliot - Infochimps, Inc
#
# Copyright 2011, InfoChimps, Inc.
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

# Graphite does not need to be runing on the same server for statsd
# to work
#include_recipe "graphite"

include_recipe "nodejs"
include_recipe "runit"

git "#{node.statsd.src_path}" do
  repository "#{node.statsd.git_uri}"
  reference "master"
  action :sync
end

template "#{node.statsd.src_path}/baseConfig.js" do
  source "baseConfig.js.erb"
  mode 0755
  notifies :restart, "service[statsd]"
end

runit_service 'statsd' do
end

provide_service ("#{node[:statsd][:cluster_name]}-statsd")

