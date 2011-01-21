package "ganglia-monitor"

service "ganglia-monitor" do
  enabled true
  running true
  pattern "gmond"
end

template "/etc/ganglia/gmond.conf" do
  source "gmond.conf.erb"
  backup false
  owner "ganglia"
  group "ganglia"
  mode 0644
  variables(
            :cluster => {
              :name => node[:cluster_name],
              :send_host => provider_private_ip("#{node[:cluster_name]}-gmetad") || "localhost",
              :send_port => 8649,
              :receive_port => 8649,
            })
  notifies :restart, resources(:service => "ganglia-monitor")
end

