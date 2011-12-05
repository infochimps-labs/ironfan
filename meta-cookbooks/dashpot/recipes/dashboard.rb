#
# Cookbook Name::       cluster_chef
# Description::         Lightweight dashboard for this machine: index of services and their dashboard snippets
# Recipe::              dashboard
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
# Make a quickie little web server to
# let you easily jump to the namenode, jobtracker or cloudera_desktop
#

include_recipe  'cluster_chef'
include_recipe  'runit'
include_recipe  'provides_service'

package         'thttpd'
package         'thttpd-util'

standard_directories(:cluster_chef) do
  directories  :home_dir, :log_dir, :conf_dir
end
directory("#{node[:cluster_chef][:home_dir]}/dashboard"){ mode '0755' ; }

cluster_chef_dashboard(:cluster_chef) do
  template_name 'index'
  action        :create

  summary_keys = %w[]
  variables     Mash.new({:summary_keys => summary_keys})
end

template "#{node[:cluster_chef][:home_dir]}/dashboard-thttpd.conf" do
  owner         "root"
  mode          "0644"
  source        "dashboard-thttpd.conf.erb"
end

runit_service "cluster_chef_dashboard" do
  run_state     node[:cluster_chef][:dashboard][:run_state]
  options       node[:cluster_chef]
end
