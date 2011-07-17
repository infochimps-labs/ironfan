#
# Install
#

%w[
  thin rack resque redis redis-namespace yajl-ruby
].each{|gem_name| gem_package gem_name }

directory node[:resque][:dir]+'/..' do
  owner     'root'
  group     'root'
  mode      "0775"
  recursive true
  action    :create
end

#
# User
#
group 'resque' do gid 336 ; action [:create] ; end
user 'resque' do
  comment    'Resque queue user'
  uid        336
  group      'resque'
  home       node[:resque][:dir]
  shell      "/bin/false"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

#
# Directories
#
[ :log_dir, :tmp_dir, :dbdir, :swapdir, :conf_dir  ].each do |dirname|
  directory node[:resque][dirname] do
    owner     node[:resque][:user]
    group     node[:resque][:group]
    mode      "0775"
    recursive true
    action    :create
  end
end

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


