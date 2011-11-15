#
# Cookbook Name::       cassandra
# Description::         Install From Release
# Recipe::              install_from_release
# Author::              Benjamin Black
#
# Copyright 2011, Benjamin Black
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

directory "/usr/local/src" do
  mode      '0775'
  owner     'root'
  group     'admin'
  action    :create
  recursive true
end

cassandra_install_pkg = File.basename(node[:cassandra][:install_url])
cassandra_install_dir = cassandra_install_pkg.gsub(%r{(?:-bin)?\.tar\.gz}, '')
# Chef::Log.info [cassandra_install_pkg, cassandra_install_dir].inspect

remote_file "/usr/local/src/"+cassandra_install_pkg do
  source    node[:cassandra][:install_url]
  mode      "0644"
  action :create
end

bash 'install from tarball' do
  user         'root'
  cwd          '/usr/local/share'
  code <<EOF
  tar xzf /usr/local/src/#{cassandra_install_pkg}
  cd  #{cassandra_install_dir}
  mv                conf/storage-conf.xml conf/storage-conf.xml.orig
  ln -nfs /etc/cassandra/storage-conf.xml conf/storage-conf.xml
EOF
  not_if {File.directory?("/usr/local/share/#{cassandra_install_dir}")}
end

link "/usr/local/share/cassandra" do
  to "/usr/local/share/"+cassandra_install_dir
  action :create
end

link "/usr/local/share/cassandra/cassandra.in.sh" do
  to "/usr/local/share/cassandra/bin/cassandra.in.sh"
  action :create
end

link "/usr/sbin/cassandra" do
  to "/usr/local/share/cassandra/bin/cassandra"
  action :create
end

include_recipe "cassandra::bintools"
