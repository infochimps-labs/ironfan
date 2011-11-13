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


pig_package_file = File.join('/usr/local/src',   File.basename(node[:pig][:install_url]))
pig_install_dir  = File.join('/usr/local/share', pig_install_pkg.gsub(%r{(?:-bin)?\.tar\.gz}, ''))

node[:pig_install_dir] = pig_install_dir

[File.dirname(pig_package_file), File.dirname(pig_install_dir)].each do |dir|
  directory(dir) do
    mode      '0775'
    owner     'root'
    group     'admin'
    action    :create
    recursive true
  end
end

remote_file pig_package_file do
  source      node[:pig][:install_url]
  mode        "0644"
  action      :create
end

bash 'unpack pig tarball' do
  user        'root'
  cwd         File.dirname(pig_install_dir)
  code        "tar xzf '#{pig_package_file}'"
  not_if{ File.directory?(pig_install_dir) }
end

bash 'build pig classes' do
  user        'root'
  cwd         pig_install_dir
  code        "ant"
  environment 'JAVA_HOME' => node[:pig][:java_home]
  not_if{ File.exists?("#{pig_install_dir}/pig.jar") }
end

link '/usr/local/share/pig' do
  to          pig_install_dir
  action      :create
end

link node[:pig][:home_dir]
  to          pig_install_dir
  action      :create
end

link "/usr/local/bin/pig" do
  to          File.join(node[:pig][:home_dir], 'bin', 'pig')
  action      :create
end
