#
# Cookbook Name::       graphite
# Description::         Carbon
# Recipe::              carbon
# Author::              Heavy Water Software Inc.
#
# Copyright 2011, Heavy Water Software Inc.
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

package "python-twisted"

remote_file "/usr/src/carbon-#{node.graphite.carbon.version}.tar.gz" do
  source node.graphite.carbon.uri
  checksum node.graphite.carbon.checksum
end

execute "untar carbon" do
  command "tar xzf carbon-#{node.graphite.carbon.version}.tar.gz"
  creates "/usr/src/carbon-#{node.graphite.carbon.version}"
  cwd "/usr/src"
end

execute "install carbon" do
  command "python setup.py install"
  creates "/opt/graphite/lib/carbon-#{node.graphite.carbon.version}-py2.6.egg-info"
  cwd "/usr/src/carbon-#{node.graphite.carbon.version}"
end

template "/opt/graphite/conf/carbon.conf" do
  variables( :line_rcvr_addr => node[:graphite][:carbon][:line_rcvr_addr],
             :pickle_rcvr_addr => node[:graphite][:carbon][:pickle_rcvr_addr],
             :cache_query_addr => node[:graphite][:carbon][:cache_query_addr] )
  notifies :restart, "service[carbon-cache]"
end

template "/opt/graphite/conf/storage-schemas.conf"

cookbook_file "/etc/init.d/carbon-cache" do
  source "init.d_carbon-cache"
  mode 0755
end

# execute "setup carbon sysvinit script" do
#   command "ln -nsf /opt/graphite/bin/carbon-cache.py /etc/init.d/carbon-cache"
#   creates "/etc/init.d/carbon-cache"
# end

service "carbon-cache" do
#   running true
#   start_command "/opt/graphite/bin/carbon-cache.py start"
#   stop_command "/opt/graphite/bin/carbon-cache.py stop"
  action [ :enable, :start ]
#   action :start
end
