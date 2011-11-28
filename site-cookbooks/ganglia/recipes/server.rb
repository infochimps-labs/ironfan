#
# Cookbook Name::       ganglia
# Description::         Server
# Recipe::              server
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2011, Chris Howe - Infochimps, Inc
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

include_recipe 'ganglia'

daemon_user('ganglia.server')

package "ganglia-webfrontend"
package "gmetad"

Chef::Log.info( [node[:ganglia].to_hash] )

#
# Create service
#

standard_directories('ganglia.server') do
  directories [:home_dir, :log_dir, :conf_dir, :pid_dir, :data_dir]
end

kill_old_service('gmetad')

runit_service "ganglia_server" do
  options       node[:ganglia]
end

provide_service("#{node[:cluster_name]}-ganglia_server")

#
# Conf file -- auto-discovers ganglia monitors
#

template "#{node[:ganglia][:conf_dir]}/gmetad.conf" do
  source        "gmetad.conf.erb"
  backup        false
  owner         "ganglia"
  group         "ganglia"
  mode          "0644"
  notifies :restart, "service[ganglia_server]", :delayed if startable?(node[:ganglia][:server])
end

#
# Finalize
#

service 'ganglia_server' do
  Array(node[:ganglia][:server][:run_state]).each do |state|
    notifies state, 'service[ganglia_server]', :delayed
  end
end
