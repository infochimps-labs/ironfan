# Packages required for further chef config

%w[
  right_aws broham configliere
].each do |pkg|
  gem_package(pkg){ action :install }
end

# Drop the node name for other processes to read easily
template "/etc/node_name" do
  mode 0644
  source "node_name.erb"
  action :create
end
