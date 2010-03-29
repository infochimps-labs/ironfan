#
# Cookbook Name:: hadoop
# Recipe:: cloudera_desktop
#
# Copyright 2010, Infochimps, Inc.
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

include_recipe "cdh"

# package 'python-devel'   # on redhat-ish
package 'libxslt1.1'
package 'cloudera-desktop'
package 'cloudera-desktop-plugins'

template '/usr/share/cloudera-desktop/conf/cloudera-desktop.ini' do
  owner "root"
  mode "0644"
  source "cloudera_desktop.ini.erb"
end

service "cloudera_desktop" do
  action [ :start, :enable ]
end

