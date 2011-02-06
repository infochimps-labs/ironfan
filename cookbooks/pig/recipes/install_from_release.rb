#
# Cookbook Name:: pig
# Recipe:: install_from_package
#
# Copyright 2009, Infochimps, Inc.
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
# Install pig from latest release
#
#   puts pig tarball into /usr/local/src/pig-xxx
#   expands it into /usr/local/share/pig-xxx
#   and links that to /usr/local/share/pig
#

directory "/usr/local/src" do
  mode      '0775'
  owner     'root'
  group     'admin'
  action    :create
  recursive true
end

pig_install_pkg     = File.basename(node[:pig][:install_url])
pig_install_dir     = pig_install_pkg.gsub(%r{(?:-bin)?\.tar\.gz}, '')
pig_hbase_path_name = File.basename(node[:pig][:pig_hbase_patch])

remote_file "/usr/local/src/#{pig_install_pkg}" do
  source    node[:pig][:install_url]
  mode      "0644"
  action :create
end

bash 'install pig from tarball' do
  user 'root'
  cwd  '/usr/local/share'
  code "tar xzf /usr/local/src/#{pig_install_pkg}"
  not_if{ File.directory?("/usr/local/share/#{pig_install_dir}") }
end

link "/usr/local/share/pig" do
  to "/usr/local/share/#{pig_install_dir}"
  action :create
end

link "/usr/local/bin/pig" do
  to "/usr/local/share/pig/bin/pig"
  action :create
end

bash 'build pig classes' do
  user 'root'
  cwd  '/usr/local/share/pig'
  environment 'JAVA_HOME' => node[:pig][:java_home]
  code "ant"
  not_if{ File.exists?("/usr/local/share/pig/pig.jar") }
end

bash 'build piggybank' do
  user 'root'
  cwd  '/usr/local/share/pig/contrib/piggybank/java'
  environment 'JAVA_HOME' => node[:pig][:java_home]
  code "ant"
  not_if{ File.exists?("/usr/local/share/pig/contrib/piggybank/java/piggybank.jar") }
end

