#
# Cookbook Name:: statsd
# Recipe:: default
#
# Copyright 2011, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "graphite"
include_recipe "nodejs"
include_recipe "runit"

package "git"

## Replaced by git-specific invocation, below
# execute "git clone statsd" do
#   cwd "/usr/src"
#   command "git clone #{node.statsd.git_uri}"
#   creates "/usr/src/statsd"
# end
git "#{node.statsd.src_path}" do
  repository "#{node.statsd.git_uri}"
  reference "master"
  action :sync
end

template "#{node.statsd.src_path}/baseConfig.js" do
  source "baseConfig.js.erb"
  mode 0755
end

template "#{node.statsd.src_path}/testStatsD.rb" do
  source "testStatsD.rb.erb"
  mode 0755
end

runit_service 'statsd' do
end
# bash "setup statsd runit directories" do
#   cwd "#{node.statsd.service_path}"
#   code <<-EOH
#   mkdir -p supervise log/main log/supervise"
#   cd supervise; touch control lock ok pid stat status;"
#   cd ../log/supervise; touch control lock ok pid stat status;"
#   EOH
#   creates "#{node.statsd.service_path}/supervise/ok"
# end
# 
# cookbook_file "#{node.statsd.service_path}/run" do
#   source "runit_run"
#   mode 0755
# end
# 
# cookbook_file "#{node.statsd.service_path}/log/run" do
#   source "runit_log_run"
#   mode 0755
# end
# 
# execute "setup statsd sysvinit script" do
#   command "ln -nsf /usr/bin/sv /etc/init.d/statsd"
#   creates "/etc/init.d/statsd"
# end
# 
# service "statsd" do
# #   start_command "cd #{node.statsd.src_path}; node stats.js baseConfig.js &"
# #   stop_command "killall node"
#   action [ :enable, :start ]
# end