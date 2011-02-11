
provide_service("#{node[:cluster_name]}-redis", :port => node[:redis][:port] )

template "/etc/init.d/redis-server" do
  source "redis-server-init-d.erb"
  owner "root"
  group "root"
  mode 0744
end

service redis_package do
  action :enable
end

template "/etc/redis/redis.conf" do
  source "redis.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies(:restart, resources(:service => redis_package)) unless node[:platform_version].to_f < 9.0
end
