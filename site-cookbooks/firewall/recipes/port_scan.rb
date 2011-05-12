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
    Chef::Log.info("OPTIONS: #{(node[:firewall][k]).merge(:name => m[1]).inspect}, node: #{(node[:firewall][k]).inspect}")
    iptables_rule "no_port_scan_#{m[1]}" do
      source "no_port_scan.erb"
      variables({ :port => node[:firewall][k][:port],
                  :max_conns => node[:firewall][k][:max_conns],
                  :window => node[:firewall][k][:window],
                  :name => m[1]
                })
    end
  end
end
