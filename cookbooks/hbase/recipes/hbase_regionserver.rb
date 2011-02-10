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
package "hadoop-hbase-regionserver"

# launch service
service "hadoop-hbase-regionserver" do
  action [ :enable, :start ]
  running true
  supports :status => true, :restart => true
end

# register with cluster_service_discovery
provide_service ("#{node[:hbase][:cluster_name]}-hbase-regionserver")
