# Author:: Nacer Laradji (<nacer.laradji@gmail.com>)
# Cookbook Name:: zabbix
# Recipe:: mysql_setup
#
# Copyright 2011, Efactures
#
# Apache 2.0
#

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)

include_recipe "mysql::client"
include_recipe "database"

# generate the password
node.set_unless[:zabbix][:server][:dbpassword] = secure_password

mysql_connection_info = {:host => "localhost", :username => 'root', :password => node['mysql']['server_root_password']}

begin
  gem_package "mysql" do
    action :install
  end
  Gem.clear_paths  
  require 'mysql'
  m=Mysql.new("localhost","root",node['mysql']['server_root_password']) 
  if m.list_dbs.include?("zabbix") == false

  # create zabbix database
  mysql_database 'zabbix' do
    connection mysql_connection_info
    action :create
    notifies :run, "execute[zabbix_populate_schema]"
    notifies :run, "execute[zabbix_populate_data]"
    notifies :run, "execute[zabbix_populate_image]"
    notifies :create, "template[/etc/zabbix/zabbix_server.conf]"
  end

  # create zabbix user
  mysql_database_user 'zabbix' do
    connection mysql_connection_info
    password node[:zabbix][:server][:dbpassword]
    action :create
  end

  # populate database
  execute "zabbix_populate_schema" do
    command "/usr/bin/mysql -u root #{node.zabbix.server.dbname} -p#{node.mysql.server_root_password} < /opt/zabbix-#{node.zabbix.server.version}/create/schema/mysql.sql"
    action :nothing
  end
  execute "zabbix_populate_data" do
    command "/usr/bin/mysql -u root #{node.zabbix.server.dbname} -p#{node.mysql.server_root_password} < /opt/zabbix-#{node.zabbix.server.version}/create/data/data.sql"
    action :nothing
  end
  execute "zabbix_populate_image" do
    command "/usr/bin/mysql -u root #{node.zabbix.server.dbname} -p#{node.mysql.server_root_password} < /opt/zabbix-#{node.zabbix.server.version}/create/data/images_mysql.sql"
    action :nothing
  end

  # Grant zabbix
  mysql_database_user 'zabbix' do
    connection mysql_connection_info
    password node[:zabbix][:server][:dbpassword]
    database_name 'zabbix'
    host 'localhost'
    privileges [:select,:update,:insert,:create,:drop,:delete]
    action :grant
  end

  end
rescue LoadError
  Chef::Log.info("Missing gem 'mysql'")
end

