#
# Cookbook Name::       hbase
# Description::         Base configuration for hbase
# Recipe::              default
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2011, Chris Howe - Infochimps, Inc
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

include_recipe "java::sun"
include_recipe "apt"
include_recipe "mountable_volumes"
include_recipe "hadoop_cluster"
include_recipe "zookeeper::client"
include_recipe "ganglia"

include_recipe "hbase::add_cloudera_repo"

#
# Users
#

group 'hbase' do
  group_name    'hbase'
  gid           node[:groups]['hbase'][:gid]
  action        [:create, :manage]
end

group 'hbase' do gid 304 ; action [:create] ; end
user 'hbase' do
  comment       'Hadoop HBase Daemon'
  uid           304
  group         'hbase'
  home          node[:hbase][:pid_dir]
  shell         "/bin/false"
  password      nil
  supports      :manage_home => false
  action        [:create, :manage]
end

# Install
package "hadoop-hbase"
package "hadoop-hbase-thrift"

[:tmp_dir, :log_dir, :pid_dir].each do |dir|
  directory node[:hbase][dir] do
    owner    'hbase'
    group    "hbase"
    mode     '0755'
    action   :create
    recursive true
  end
end

#
# Configuration files
#
# Find these variables in ../hadoop_cluster/libraries/hadoop_cluster.rb
#
%w[ hbase-env.sh hbase-site.xml hadoop-metrics.properties ].each do |conf_file|
  template "/etc/hbase/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    variables({
        :namenode_fqdn          => provider_fqdn("#{node[:hbase][:cluster_name]}-namenode"),
        :jobtracker_addr     => provider_private_ip("#{node[:hbase][:cluster_name]}-jobtracker"),
        :zookeeper_addr      => all_provider_private_ips("#{node[:hbase][:cluster_name]}-zookeeper").join(","),
        :private_ip             => private_ip_of(node),
        :jmx_hostname           => public_ip_of(node),
        :ganglia                => provider_for_service("#{node[:hbase][:cluster_name]}-gmetad"),
        :ganglia_addr        => provider_fqdn("#{node[:hbase][:cluster_name]}-gmetad"),
        :ganglia_port           => 8649,
        :period                 => 10
      })
    source "#{conf_file}.erb"
  end
end


if node[:hadoop] && node[:hadoop][:conf_dir]
  link "#{node[:hadoop][:conf_dir]}/hbase-site.xml" do
    to "#{node[:hbase][:conf_dir]}/hbase-site.xml"
    only_if{ File.directory?(node[:hadoop][:conf_dir]) }
  end
end

# Stuff the HBase jars into the classpath
node[:hadoop][:extra_classpaths][:hbase] = '/usr/lib/hbase/hbase.jar:/usr/lib/hbase/lib/zookeeper.jar:/usr/lib/hbase/conf' if node[:hadoop] and node[:hadoop][:extra_classpaths]
