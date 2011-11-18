#
# Cookbook Name::       graphite
# Description::         Web
# Recipe::              web
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

include_recipe "apache2::mod_python"

package "python-cairo-dev"
package "python-django"
package "python-memcache"
package "python-rrdtool"

install_from_release('graphite_web') do
  release_url   node[:graphite][:graphite_web][:release_url]
  home_dir      node[:graphite][:graphite_web][:home_dir]
  checksum      node[:graphite][:graphite_web][:release_url_checksum]
  action        [:install]
end

graphite_web_version = node[:graphite][:graphite_web][:version]

remote_file "#{node[:graphite][:prefix_root]}/src/graphite-web-#{graphite_web_version}/webapp/graphite/storage.py.patch" do
  source        "http://launchpadlibrarian.net/65094495/storage.py.patch"
  checksum      "8bf57821"
end

execute "patch graphite-web" do
  command       "patch storage.py storage.py.patch"
  creates       "/opt/graphite/webapp/graphite_web-#{graphite_web_version}-py2.6.egg-info"
  cwd           "/usr/src/graphite-web-#{graphite_web_version}/webapp/graphite"
end

execute "install graphite-web" do
  command       "python setup.py install"
  creates       "/opt/graphite/webapp/graphite_web-#{graphite_web_version}-py2.6.egg-info"
  cwd           "/usr/src/graphite-web-#{graphite_web_version}"
end

template "#{node[:apache][:dir]}/sites-available/graphite.conf" do
  source        "graphite-vhost.conf.erb"
end

apache_site "000-default" do
  enable        false
end

apache_site "graphite.conf"

directory "#{node[:graphite][:log_dir]}" do
  owner         node[:graphite][:graphite_web][:user]
  group         node[:graphite][:graphite_web][:user]
end

directory "/opt/graphite/storage" do
  owner         node[:graphite][:graphite_web][:user]
  group         node[:graphite][:graphite_web][:user]
end

cookbook_file "/opt/graphite/storage/graphite.db" do
  owner         node[:graphite][:graphite_web][:user]
  group         node[:graphite][:graphite_web][:user]
  action        :create_if_missing
end
