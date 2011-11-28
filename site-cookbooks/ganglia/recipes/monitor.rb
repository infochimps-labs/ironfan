#
# Cookbook Name::       ganglia
# Description::         Client
# Recipe::              client
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

daemon_user('ganglia.monitor')

package "ganglia-monitor"

#
# Create service
#

standard_directories('ganglia.monitor') do
  directories [:home_dir, :log_dir, :conf_dir, :pid_dir, :data_dir]
end

kill_old_service('ganglia-monitor'){ pattern 'gmond' }

runit_service "ganglia_monitor" do
  options       node[:ganglia]
end

service("ganglia_monitor"){ action node[:ganglia][:monitor][:service_state] }

provide_service("#{node[:cluster_name]}-ganglia_monitor",
  :monitor_group => node[:cluster_name],
  :rcv_port      => node[:ganglia][:rcv_port ])

#
# Discover ganglia server, construct conf file
#

template "#{node[:ganglia][:conf_dir]}/gmond.conf" do
  source        "gmond.conf.erb"
  backup        false
  owner         "ganglia"
  group         "ganglia"
  mode          "0644"
  send_addr = provider_private_ip("#{node[:cluster_name]}-ganglia_server") || "localhost"
  variables(
    :cluster => {
      :name      => node[:cluster_name],
      :send_addr => send_addr,
      :send_port => node[:ganglia][:send_port],
      :rcv_port  => node[:ganglia][:rcv_port ],
    })
  notifies      :restart, 'service[ganglia_monitor]' if startable?(node[:ganglia][:monitor])
end

#
# Finalize
#

service 'ganglia_monitor' do
  Array(node[:ganglia][:monitor][:service_state]).each do |state|
    notifies state, 'service[ganglia_monitor]', :delayed
  end
end
