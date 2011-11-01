# Author:: Nacer Laradji (<nacer.laradji@gmail.com>)
# Cookbook Name:: zabbix
# Recipe:: server
#
# Copyright 2011, Efactures
#
# Apache 2.0
#

if node[:zabbix][:server][:install] == true
  include_recipe "zabbix::server_#{node.zabbix.server.install_method}"
end

if node[:zabbix][:web][:install] == true
  include_recipe "zabbix::web"
end