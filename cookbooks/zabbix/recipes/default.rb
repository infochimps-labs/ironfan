# Author:: Nacer Laradji (<nacer.laradji@gmail.com>)
# Cookbook Name:: zabbix
# Recipe:: default
#
# Copyright 2011, Efactures
#
# Apache 2.0
#

# Create zabbix User
user "zabbix" do
  comment "zabbix User"
  home "/opt/zabbix"
  shell "/bin/bash"
end

# Define zabbix Agent folder
zabbix_dirs = [
  "/etc/zabbix",
  "/etc/zabbix/include",
  "/var/log/zabbix",
  "/opt/zabbix",
  "/opt/zabbix/bin",
  "/opt/zabbix/sbin",
  "/var/run/zabbix",
  "/etc/zabbix/externalscripts",
  "/opt/zabbix/AlertScriptsPath"
]

# Create zabbix folder
zabbix_dirs.each do |dir|
  directory dir do
    owner "zabbix"
    group "zabbix"
    mode "755"
  end
end


if node[:zabbix][:agent][:install] == true
  include_recipe "zabbix::agent_#{node.zabbix.agent.install_method}"
end

