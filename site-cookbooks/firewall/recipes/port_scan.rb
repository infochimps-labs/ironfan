#
# Cookbook Name:: firewall
# Recipe:: port_scan
#
# Copyright 2011, Librato, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'iptables'

(node[:firewall] || {}).keys.each do |k|
  m = k.to_s.match(/^port_scan_(.*)/)
  if m
    iptables_rule "no_port_scan_#{m[1]}" do
      source "no_port_scan.erb"
      variables(node[:firewall][k])
    end
  end
end
