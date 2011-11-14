#
# Cookbook Name:: hbase
# Recipe:: stargate
#
# Copyright 2010, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "hbase"

cookbook_file "/etc/init.d/hadoop-hbase-stargate" do
  owner "root"
  mode "0744"
  source "hadoop-hbase-stargate"
end

# launch service
service "hadoop-hbase-stargate" do
  action [ :enable, :start ]
  running true
  supports :status => true, :restart => true
end

provide_service ("#{node[:hbase][:cluster_name]}-hbase-stargate")
