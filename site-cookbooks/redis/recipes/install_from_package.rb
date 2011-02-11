
redis_package = "redis-server"

unless node[:platform_version].to_f < 9.0
  package redis_package do
    action :install
  end
end
