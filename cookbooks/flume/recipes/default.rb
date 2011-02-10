#
# Cookbook Name:: flume
# Recipe:: default
#
# Copyright 2011, Infochimps, Inc.
#
# All rights reserved - Do Not Redistribute
#

package "flume"

flume_cluster = node[:fume][:cluster_name]
 
template_vars = {
  :master_id       => node[:node_name],
  :masters         => all_provider_private_ips( "#{flume_cluster}-flume-master" ),
  :plugin_classes  => node[:flume][:plugin_classes],
  :flume_classpath => node[:flume][:classpath].join(":"),
  :zookeepers      => if node[:flume][:master][:external_zookeeper] then
                          all_provider_private( "#{flume_cluster}->zookeeper-server" )
                        else
                          nil
                        end,
  :zookeeper_port => node[:flume][:zookeeper_port],
}

template "/etc/flume/conf/flume-site.xml" do
  source "flume-site.xml.erb"
  owner  "root"
  mode   "0644"
  variables(template_vars)
end

template "/usr/lib/flume/bin/flume-env.sh" do
  source "flume-env.sh.erb"
  owner  "root"
  mode   "0744"
  variables(template_vars)
end
