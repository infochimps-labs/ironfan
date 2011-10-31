
provide_service("#{node[:elasticsearch][:cluster_name]}-data_esnode")

# Tell ElasticSearch where to find its other nodes
provide_service "#{node[:cluster_name]}-elasticsearch"
if node[:elasticsearch][:seeds].nil?
    node[:elasticsearch][:seeds] = all_provider_private_ips("#{node[:cluster_name]}-elasticsearch").sort().map { |ip| ip+':9300' }
end

runit_service "elasticsearch" do
  run_restart false               # don't automatically start or restart daemons
  action      []
end

# runit_service "elasticsearch2" do
#   run_restart false               # don't automatically start or restart daemons
#   action      []
# end
