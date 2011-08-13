
#
# Config
#

# Redis config
template File.join(node[:resque][:conf_dir], 'resque_redis.conf') do
  source 'resque_redis.conf.erb'
  mode 0664
  group 'admin'
  action :create
end

# include resque_conf in your scripts
template File.join(node[:resque][:conf_dir], 'resque_conf.rb') do
  source 'resque_conf.rb.erb'
  mode 0664
  group 'admin'
  action :create
end

#
# Daemonize
#

runit_service 'resque_redis' do
  run_restart false
end
provide_service('resque_redis', :port => node[:resque][:queue_port])

runit_service 'resque_dashboard' do
  run_restart false
end
provide_service('resque_dashboard', :port => node[:resque][:dashboard_port])
