#
# Cookbook Name::       elasticsearch
# Recipe::              install_from_release
# Author::              GoTime, modifications by Infochimps
#
# Copyright 2011, GoTime, modifications by Infochimps
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

# FIXME -- this needs to be done immediately
package "unzip" do
  action :install
end

remote_file "/tmp/elasticsearch-#{node[:elasticsearch][:version]}.zip" do
  source        "https://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-#{node[:elasticsearch][:version]}.zip"
  mode          "0644"
  # checksum      node[:elasticsearch][:checksum]
end

# install into eg. /usr/local/share/elasticsearch-0.x.x ...
directory "#{node[:elasticsearch][:install_dir]}-#{node[:elasticsearch][:version]}" do
  owner       "root"
  group       "root"
  mode        0755
end
# ... and then force /usr/lib/elasticsearch to link to the versioned dir
link node[:elasticsearch][:install_dir] do
  to "#{node[:elasticsearch][:install_dir]}-#{node[:elasticsearch][:version]}"
end

bash "unzip elasticsearch" do
  user          "root"
  cwd           "/tmp"
  code           %(unzip /tmp/elasticsearch-#{node[:elasticsearch][:version]}.zip)
  not_if{ File.exists? "/tmp/elasticsearch-#{node[:elasticsearch][:version]}" }
end

bash "copy elasticsearch root" do
  user          "root"
  cwd           "/tmp"
  code          %(cp -r /tmp/elasticsearch-#{node[:elasticsearch][:version]}/* #{node[:elasticsearch][:install_dir]})
  not_if{ File.exists? "#{node[:elasticsearch][:install_dir]}/lib" }
end
