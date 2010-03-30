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
