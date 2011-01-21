package "ganglia-webfrontend"
package "gmetad"

service "gmetad" do
  enabled true
end

cluster_nodes = {}
search(:node, '*:*') do |node|
  next unless node['ganglia'] && node['ganglia']['cluster_name']
  cluster_nodes[node['ganglia']['cluster_name']] ||= []
  cluster_nodes[node['ganglia']['cluster_name']] << node['fqdn'].split('.').first
end

template "/etc/ganglia/gmetad.conf" do
  source "gmetad.conf.erb"
  backup false
  owner "ganglia"
  group "ganglia"
  mode 0644
  variables(:cluster_nodes => cluster_nodes, :clusters => search(:ganglia_clusters, "*:*"))
  notifies :restart, resources(:service => "gmetad")
end

directory "/var/lib/ganglia/rrds" do
  owner "ganglia"
  group "ganglia"
end


