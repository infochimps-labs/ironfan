flume_logical_node "magic" do
  source "console"
  sink   "console"
  flow   "test_flow"
  physical_node node[:fqdn]
  flume_master "10.245.205.67" #all_provider_private_ips( "#{node[:flume_cluster]}-flume-master" ).sort.first
  action [:spawn,:config]
end
