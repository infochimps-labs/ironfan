# Author:: Nacer Laradji (<nacer.laradji@gmail.com>)
# Cookbook Name:: zabbix
# Recipe:: mysql_setup
#
# Copyright 2011, Efactures
#
# Apache 2.0
#

# Execute apache2 receipe + mod_php5 receipe
include_recipe "apache2"
include_recipe "apache2::mod_php5"

case node[:platform]
when "ubuntu","debian"
  # Dependencie installation
  package "php5-mysql" do
    action :install
    notifies :restart, "service[apache2]"
  end

  package "php5-gd" do
    action :install
    notifies :restart, "service[apache2]"
  end
when "centos"
  log "No centos Support yet"
end

# Link to the web interface version
link "/opt/zabbix/web" do
  to "/opt/zabbix-#{node.zabbix.server.version}/frontends/php"
end

# Give access to www-data to zabbix frontend config folder
directory "/opt/zabbix-#{node.zabbix.server.version}/frontends/php" do
  owner "www-data"
  group "www-data"
  mode "0755"
  recursive true
  action :create
end

if node[:zabbix][:web][:fqdn] != nil
  #install vhost for zabbix frontend
  web_app "#{node.zabbix.web.fqdn}" do
    server_name node.zabbix.web.fqdn
    server_aliases "zabbix"
    docroot "/opt/zabbix/web"
  end  
end