package "python-twisted"

remote_file "/usr/src/carbon-#{node.graphite.carbon.version}.tar.gz" do
  source node.graphite.carbon.uri
  checksum node.graphite.carbon.checksum
end

execute "untar carbon" do
  command "tar xzf carbon-#{node.graphite.carbon.version}.tar.gz"
  creates "/usr/src/carbon-#{node.graphite.carbon.version}"
  cwd "/usr/src"
end

execute "install carbon" do
  command "python setup.py install"
  creates "/opt/graphite/lib/carbon-#{node.graphite.carbon.version}-py2.6.egg-info"
  cwd "/usr/src/carbon-#{node.graphite.carbon.version}"
end

template "/opt/graphite/conf/carbon.conf" do
  variables( :line_receiver_interface => node[:graphite][:carbon][:line_receiver_interface],
             :pickle_receiver_interface => node[:graphite][:carbon][:pickle_receiver_interface],
             :cache_query_interface => node[:graphite][:carbon][:cache_query_interface] )
  notifies :restart, "service[carbon-cache]"
end

template "/opt/graphite/conf/storage-schemas.conf"

cookbook_file "/etc/init.d/carbon-cache" do
  source "init.d_carbon-cache"
  mode 0755
end

# execute "setup carbon sysvinit script" do
#   command "ln -nsf /opt/graphite/bin/carbon-cache.py /etc/init.d/carbon-cache"
#   creates "/etc/init.d/carbon-cache"
# end

service "carbon-cache" do
#   running true
#   start_command "/opt/graphite/bin/carbon-cache.py start"
#   stop_command "/opt/graphite/bin/carbon-cache.py stop"
  action [ :enable, :start ]
#   action :start
end
