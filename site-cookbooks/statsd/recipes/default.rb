#
# Cookbook Name:: statsd
# Recipe:: default
#
# Copyright 2011, InfoChimps, Inc.
#

# Graphite does not need to be runing on the same server for statsd
# to work
#include_recipe "graphite"

include_recipe "nodejs"
include_recipe "runit"

package "git"

git "#{node.statsd.src_path}" do
  repository "#{node.statsd.git_uri}"
  reference "master"
  action :sync
end

template "#{node.statsd.src_path}/baseConfig.js" do
  source "baseConfig.js.erb"
  mode 0755
  notifies :restart, "service[statsd]"
end

runit_service 'statsd' do
end

provide_service ("#{node[:statsd][:cluster_name]}-statsd")

