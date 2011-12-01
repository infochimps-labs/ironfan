#
# Cookbook Name::       pig
# Description::         Link in jars from hbase and zookeeper
# Recipe::              integration
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

[:zookeeper, :hbase].each do |other_system|
  next unless node[other_system]

  #
  # Link hbase, zookeeper, etc jars to $PIG_HOME/lib
  #
  [node[other_system][:exported_jars]].flatten.compact.each do |jar|
    link File.join(node[:pig][:home_dir], 'lib', File.basename(jar)) do
      to        jar
      action    :create
    end
  end

  #
  # Link hbase configuration to $PIG_HOME/conf
  #
  [node[other_system][:exported_confs]].flatten.compact.each do |xml_conf|
    link "#{node[:pig][:home_dir]}/conf/#{File.basename(xml_conf)}" do
      to xml_conf
      action :create
    end
  end

end

Chef::Log.warn "FIXME: not overwriting pig files, just putting a .new file next to it -- verify these are a) needed and b) correct"

#
# Pig configuration, by default HBASE_CONF_DIR is set to garbage
#
template "#{node[:pig][:home_dir]}/bin/pig.new" do
  owner       "root"
  mode        "0644"
  source      "pig.erb"
end

#
# Pig configuration, by default HBASE_CONF_DIR is set to garbage
#
template "#{node[:pig][:home_dir]}/conf/pig-env.sh.new" do
  owner       "root"
  mode        "0644"
  source      "pig-env.sh.erb"
end

#
# Pig config stuff
#
template "#{node[:pig][:home_dir]}/conf/pig.properties.new" do
  owner       "root"
  mode        "0644"
  source      "pig.properties.erb"
end
