#
# Cookbook Name:: flume
# Recipe:: default
#
# Copyright 2011, Infochimps, Inc.
#
# All rights reserved - Do Not Redistribute
#

# We need to explicitly include the default recipe, because we need access
# to the templates.
include_recipe "flume::default"

package "flume-master"

service "flume-master" do
  supports :restart => true, :start=>true, :stop => true
  subscribes :restart,resources( :template => ["/usr/lib/flume/conf/flume-site.xml","/usr/lib/flume/bin/flume-env.sh"] )
end

provide_service ("#{node[:flume][:cluster_name]}-flume-master")
