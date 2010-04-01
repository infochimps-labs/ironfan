package "nfs-kernel-server"

template "/etc/exports" do
  source "exports.erb"
  owner "root"
  group "root"
  mode 0644
end

service "nfs-kernel-server" do
  action [ :enable, :start ]
  running true
  supports :status => true, :restart => true
end

# gee I wish I could do this:
# set[:nfs][:server] = node[:cloud][:private_ips].first
