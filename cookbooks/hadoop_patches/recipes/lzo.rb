#
# Cookbook Name:: lzo_hadoop
# Recipe:: default
#
# Copyright 2010, Infochimps
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

package 'liblzo2-dev'
package 'debhelper'
package 'devscripts'

include_recipe "hadoop_cluster"
# ant, ant-nodeps, gcc-c++, lzo2-devel lzo

#
# Install LZO support into hadoop-0.20
#

directory "/usr/local/src" do
  mode      '0775'
  owner     'root'
  group     'admin'
  action    :create
  recursive true
end

hdplzo_install_repo = 'git://github.com/kevinweil/hadoop-lzo.git'
hdplzo_install_dir  = 'hadoop-lzo'

bash 'install hdplzo from git' do
  user 'root'
  cwd  '/usr/local/src'
  code "git clone git://github.com/kevinweil/hadoop-lzo.git #{hdplzo_install_dir}"
  not_if{ File.directory?("/usr/local/src/#{hdplzo_install_dir}") }
end

link "/usr/local/share/hdplzo" do
  to "/usr/local/src/#{hdplzo_install_dir}"
  action :create
end

bash 'build hdplzo classes' do
  user 'root'
  cwd  '/usr/local/share/hdplzo'
  code "ant"
  not_if{ File.exists?("/usr/local/share/hdplzo/hdplzo.jar") }
end

