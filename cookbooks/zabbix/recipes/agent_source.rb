# Author:: Nacer Laradji (<nacer.laradji@gmail.com>)
# Cookbook Name:: zabbix
# Recipe:: agent_source
#
# Copyright 2011, Efactures
#
# Apache 2.0
#

case node[:platform]
when "ubuntu","debian"
  # install some dependencies
  %w{ fping libcurl3 libiksemel-dev libiksemel3 libsnmp-dev libiksemel-utils libcurl4-openssl-dev }.each do |pck|
    package "#{pck}" do
      action :install
    end
  end
when "centos"
  log "No centos Support yet"
end


# Download zabbix source code
remote_file "/opt/zabbix-#{node.zabbix.agent.version}.tar.gz" do
  source "http://freefr.dl.sourceforge.net/project/zabbix/#{node.zabbix.agent.branch}/#{node.zabbix.agent.version}/zabbix-#{node.zabbix.agent.version}.tar.gz"
  mode "0644"
  action :create_if_missing
  notifies :run, "script[install_zabbix_agent]"
end

# installation of zabbix bin
script "install_zabbix_agent" do
  interpreter "bash"
  user "root"
  cwd "/opt"
  action :nothing
  notifies :restart, "service[zabbix_agentd]", :delayed
  code <<-EOH
  tar xvfz zabbix-#{node.zabbix.agent.version}.tar.gz
  (cd zabbix-#{node.zabbix.agent.version} && ./configure --enable-agent #{node.zabbix.agent.configure_options.join(" ")})
  (cd zabbix-#{node.zabbix.agent.version} && make install)
  EOH
end

# Install configuration
template "/etc/zabbix/zabbix_agentd.conf" do
  source "zabbix_agentd.conf.erb"
  owner "root"
  group "root"
  mode "644"
  notifies :restart, "service[zabbix_agentd]", :delayed
end

# Install Init script
template "/etc/init.d/zabbix_agentd" do
  source "zabbix_agentd.init.erb"
  owner "root"
  group "root"
  mode "754"
end

# Define zabbix_agentd service
service "zabbix_agentd" do
  supports :status => true, :start => true, :stop => true
  action [ :start, :enable ]
end
