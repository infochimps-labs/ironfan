#
# Cookbook Name:: zabbix
# Attributes:: default

default[:zabbix][:agent][:servers] = []
default[:zabbix][:agent][:configure_options] = [ "--prefix=/opt/zabbix", "--with-libcurl"]
default[:zabbix][:agent][:branch] = "ZABBIX%20Latest%20Stable"
default[:zabbix][:agent][:install] = true
default[:zabbix][:agent][:version] = "1.8.5"
default[:zabbix][:agent][:install_method] = "prebuild"

default[:zabbix][:server][:install] = false
default[:zabbix][:server][:version] = "1.8.8"
default[:zabbix][:server][:branch] = "ZABBIX%20Latest%20Stable"
default[:zabbix][:server][:dbhost] = "localhost"
default[:zabbix][:server][:dbname] = "zabbix"
default[:zabbix][:server][:dbuser] = "zabbix"
default[:zabbix][:server][:dbpassword] = nil
default[:zabbix][:server][:dbport] = "3306"
default[:zabbix][:server][:install_method] = "source"
default[:zabbix][:server][:configure_options] = [ "--prefix=/opt/zabbix","--with-libcurl","--with-net-snmp","--with-mysql " ]

default[:zabbix][:web][:install] = false
default[:zabbix][:web][:fqdn] = nil

