# Author:: Nacer Laradji (<nacer.laradji@gmail.com>)
# Cookbook Name:: zabbix
# Recipe:: server_source
#
# Copyright 2011, Efactures
#
# Apache 2.0
#

case node[:platform]
when "ubuntu","debian"
  # install some dependencies
  %w{ fping libmysql++-dev libmysql++3 libcurl3 libiksemel-dev libiksemel3 libsnmp-dev snmp libiksemel-utils libcurl4-openssl-dev }.each do |pck|
    package "#{pck}" do
      action :install
    end
  end
when "centos"
  log "No centos Support yet"
end


# installation of zabbix bin
script "install_zabbix_server" do
  interpreter "bash"
  user "root"
  cwd "/opt"
  action :nothing
  notifies :restart, "service[zabbix_server]"
  code <<-EOH
  tar xvfz /opt/zabbix-#{node.zabbix.server.version}.tar.gz
  (cd zabbix-#{node.zabbix.server.version} && ./configure --enable-server #{node.zabbix.server.configure_options.join(" ")})
  (cd zabbix-#{node.zabbix.server.version} && make install)
  EOH
end

# Download zabbix source code
remote_file "/opt/zabbix-#{node.zabbix.server.version}.tar.gz" do
  source "http://freefr.dl.sourceforge.net/project/zabbix/#{node.zabbix.server.branch}/#{node.zabbix.server.version}/zabbix-#{node.zabbix.server.version}.tar.gz"
  mode "0644"
  action :create_if_missing
  notifies :run, "script[install_zabbix_server]"
end

# Install Init script
template "/etc/init.d/zabbix_server" do
  source "zabbix_server.init.erb"
  owner "root"
  group "root"
  mode "754"
end

# install zabbix server conf
template "/etc/zabbix/zabbix_server.conf" do
  source "zabbix_server.conf.erb"
  owner "root"
  group "root"
  mode "644"
  notifies :restart, "service[zabbix_server]"
end

# Define zabbix_agentd service
service "zabbix_server" do
  supports :status => true, :start => true, :stop => true
  action [ :start, :enable ]
end

if node.attribute[:mysql][:server_root_password]
  include_recipe "zabbix::mysql_setup"
end