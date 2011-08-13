# Drop the node name for other processes to read easily
template "/etc/node_name" do
  mode 0644
  source "node_name.erb"
  action :create
end
