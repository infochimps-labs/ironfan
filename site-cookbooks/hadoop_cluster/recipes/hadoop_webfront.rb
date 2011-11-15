#
# Cookbook Name::       hadoop_cluster
# Description::         Hadoop Webfront
# Recipe::              hadoop_webfront
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

package 'thttpd'

case node[:platform]
when 'debian', 'ubuntu'    then www_base = '/var/www'             # debian-ish
else                            www_base = '/var/www/thttpd/html' # redhat-ish
end

template "#{www_base}/index.html" do
  owner "root"
  mode "0644"
  source "webfront_index.html.erb"
end

execute "Enable thttpd" do
  command %Q{sed -i -e 's|ENABLED=no|ENABLED=yes|' /etc/default/thttpd}
  not_if "grep 'ENABLED=yes' '/etc/default/thttpd'"
end

service "thttpd" do
  action [ :start, :enable ]
end
