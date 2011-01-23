
provide_service("#{node[:elasticsearch][:cluster_name]}-data_esnode")

runit_service "elasticsearch" do
  run_restart false               # don't automatically start or restart daemons
  action      []
end

# runit_service "elasticsearch2" do
#   run_restart false               # don't automatically start or restart daemons
#   action      []
# end
