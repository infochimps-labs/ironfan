#
# Cookbook Name:: pig
# Recipe:: install_from_package
#
# Copyright 2009, Opscode, Inc.
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

package "hadoop-pig"

#
# Link hbase jars to $PIG_HOME/lib
#
node[:pig][:hbase_jars].each do |hbase_jar|
  link "/usr/lib/pig/lib/#{hbase_jar}" do
    to "/usr/lib/hbase/#{hbase_jar}"
    action :create
  end
end

#
# Link zookeeper jars to $PIG_HOME/lib
#
node[:pig][:zookeeper_jars].each do |zoo_jar|
  link "/usr/lib/pig/lib/#{zoo_jar}" do
    to "/usr/lib/zookeeper/#{zoo_jar}"
    action :create
  end
end


#
# Link hbase configuration to $PIG_HOME/conf
#
node[:pig][:hbase_configs].each do |xml_conf|
  link "/usr/lib/pig/conf/#{xml_conf}" do
    to "/etc/hbase/conf/#{xml_conf}"
    action :create
  end
end

#
# Pig configuration
#
template "/usr/lib/pig/conf/pig.properties" do
  owner "root"
  mode "0644"
  source "pig.properties.erb"
end

# bash 'build piggybank' do
#   user 'root'
#   cwd  '/usr/local/share/pig/contrib/piggybank/java'
#   environment 'JAVA_HOME' => node[:pig][:java_home]
#   code "ant"
#   not_if{ File.exists?("/usr/local/share/pig/contrib/piggybank/java/piggybank.jar") }
# end
