#
# Cookbook Name:: hbase
# Recipe:: default
#
# Copyright 2010, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "hbase"

# Install
package "hadoop-hbase-master"

# launch service
service "hadoop-hbase-master" do
  action [ :enable, :start ]
  running true
  supports :status => true, :restart => true
end

# register with cluster_service_discovery
provide_service ("#{node[:cluster_name]}-hbase-master")
