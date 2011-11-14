#
# Cookbook Name::       graphite
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

remote_file "/usr/src/graphite-web-#{node.graphite.graphite_web.version}.tar.gz" do
  source node.graphite.graphite_web.uri
  checksum node.graphite.graphite_web.checksum
end

execute "untar graphite-web" do
  command "tar xzf graphite-web-#{node.graphite.graphite_web.version}.tar.gz"
  creates "/usr/src/graphite-web-#{node.graphite.graphite_web.version}"
  cwd "/usr/src"
end

remote_file "/usr/src/graphite-web-#{node.graphite.graphite_web.version}/webapp/graphite/storage.py.patch" do
  source "http://launchpadlibrarian.net/65094495/storage.py.patch"
  checksum "8bf57821"
end

execute "patch graphite-web" do
  command "patch storage.py storage.py.patch"
  creates "/opt/graphite/webapp/graphite_web-#{node.graphite.graphite_web.version}-py2.6.egg-info"
  cwd "/usr/src/graphite-web-#{node.graphite.graphite_web.version}/webapp/graphite"
end

execute "install graphite-web" do
  command "python setup.py install"
  creates "/opt/graphite/webapp/graphite_web-#{node.graphite.graphite_web.version}-py2.6.egg-info"
  cwd "/usr/src/graphite-web-#{node.graphite.graphite_web.version}"
end

template "/etc/apache2/sites-available/graphite" do
  source "graphite-vhost.conf.erb"
end

apache_site "000-default" do
  enable false
end

apache_site "graphite"

directory "/opt/graphite/storage/log/webapp" do
  owner "www-data"
  group "www-data"
end

directory "/opt/graphite/storage" do
  owner "www-data"
  group "www-data"
end

cookbook_file "/opt/graphite/storage/graphite.db" do
  owner "www-data"
  group "www-data"
  action :create_if_missing
end
