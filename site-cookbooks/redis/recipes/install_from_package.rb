unless node[:platform_version].to_f < 9.0
  package "redis-server" do
    action :install
  end
end
