flume_logical_node "magic" do
  source "console"
  sink   "console"
  flow   "test_flow"
  physical_node node[:fqdn]
  #flume_master "10.245.205.67" #
  flume_master provider_private_ip( "#{node[:flume][:cluster_name]}-flume-master" )
  action [:spawn,:config]
end
