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

#
# Register with Broham
#
begin
  require 'broham'
  Settings.access_key        = node[:aws][:aws_access_key]
  Settings.secret_access_key = node[:aws][:aws_secret_access_key]
  Broham.establish_connection
  Broham.create_domain

  mount_point   = node[:nfs][:exports].keys.first
  mount_options = node[:nfs][:exports][mount_point][:nfs_options]
  resp = Broham.register 'nfs_server', :client_path => mount_point, :mount_options => mount_options
  p resp
rescue Exception => e
  warn e.backtrace.join("\n")
end
