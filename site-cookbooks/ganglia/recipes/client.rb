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

package "ganglia-monitor"

service "ganglia-monitor" do
  enabled true
  running true
  pattern "gmond"
end

template "/etc/ganglia/gmond.conf" do
  source "gmond.conf.erb"
  backup false
  owner "ganglia"
  group "ganglia"
  mode 0644
  variables(
            :cluster => {
              :name => node[:cluster_name],
              :send_host => provider_private_ip("#{node[:cluster_name]}-gmetad") || "localhost",
              :send_port => 8649,
              :receive_port => 8649,
            })
  notifies :restart, resources(:service => "ganglia-monitor")
end

