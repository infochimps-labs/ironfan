#
# Cookbook Name:: flume
# Recipe:: default
#
# Copyright 2011, Infochimps, Inc.
#
# All rights reserved - Do Not Redistribute
#

package "flume"

flume_cluster = node[:flume][:cluster_name]
# All of the configs need to have the flume masters listed in the same order
masters = all_provider_private_ips( "#{flume_cluster}-flume-master" ).sort

# The master_id should be the index of the machine into the masters array
master_id = masters.find_index( private_ip_of( node ) ) 

template_vars = {
  :master_id       => master_id,
  :masters         => masters,
  :plugin_classes  => node[:flume][:plugin_classes],
  :flume_classpath => node[:flume][:classpath].join(":"),
  :zookeepers      => if node[:flume][:master][:external_zookeeper] then
                          all_provider_private_ips( "#{flume_cluster}-zookeeper" )
                        else
                          nil
                        end,
  :zookeeper_port => node[:flume][:master][:zookeeper_port],
}

template_vars[:master_id]

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
