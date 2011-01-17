#
# Cookbook Name:: hbase
# Recipe:: default
#
# Copyright 2010, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "hadoop_cluster"

group 'hbase' do
  group_name 'hbase'
  gid         node[:groups]['hbase'][:gid]
  action      [:create, :manage]
end

user 'hbase' do
  comment    'Hadoop HBase Daemon'
  uid        304
  group      'hbase'
  home       "/var/run/hadoop-0.20"
  shell      "/bin/false"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

# Install
package "hadoop-hbase"
package "hadoop-hbase-thrift"

%w[/var/run/hbase /var/log/hbase].each do |dir|
  directory dir do
    owner    'hbase'
    group    "hadoop"
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
template_variables = {
  :namenode_address       => provider_private_ip("#{node[:cluster_name]}-namenode"),
  :jobtracker_address     => provider_private_ip("#{node[:cluster_name]}-jobtracker"),
  :zookeeper_address      => provider_private_ip("#{node[:cluster_name]}-zookeeper"),
  :private_ip             => private_ip_of(node),
}
Chef::Log.debug template_variables.inspect
%w[ hbase-env.sh hbase-site.xml ].each do |conf_file|
  template "/etc/hbase/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(template_variables)
    source "#{conf_file}.erb"
  end
end

# bump
