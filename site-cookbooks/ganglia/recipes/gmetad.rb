package "gmetad"

service "gmetad" do
  enabled true
end

provide_service ("#{node[:cluster_name]}-gmetad")

cluster_nodes = { node['cluster_name'] => [ node['ip-address'] ] }

template "/etc/ganglia/gmetad.conf" do
  source "gmetad.conf.erb"
  backup false
  owner "ganglia"
  group "ganglia"
  mode 0644
  variables(:cluster_nodes => cluster_nodes, :clusters => [ node['cluster_name'] ])
  notifies :restart, resources(:service => "gmetad")
end

directory "/var/lib/ganglia/rrds" do
  owner "ganglia"
  group "ganglia"
end


