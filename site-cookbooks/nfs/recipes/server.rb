package "nfs-kernel-server"

if node[:nfs] && node[:nfs][:exports]
  provide_service('nfs_server', node[:nfs][:exports].to_hash)

  service "nfs-kernel-server" do
    action [ :enable, :start ]
    running true
    supports :status => true, :restart => true
  end

  template "/etc/exports" do
    source "exports.erb"
    owner "root"
    group "root"
    mode 0644
    notifies  :restart, resources(:service => "nfs-kernel-server")
  end
else
  Chef::Log.warn "You included the NFS server recipe without defining nfs exports: set node[:nfs][:exports]."
end

#
# For problems starting NFS server on ubuntu maverick systems: read, understand
# and then run /tmp/fix_nfs_on_maverick_amis.sh
#
if (node[:lsb][:release].to_f == 10.10) && (`service nfs-kernel-server status` =~ /not running/)
  template "/tmp/fix_nfs_on_maverick_amis.sh" do
    source "fix_nfs_on_maverick_amis.sh"
    owner "root"
    group "root"
    mode 0700
  end
  Chef::Log.warn "\n\n****\nFor problems starting NFS server on ubuntu maverick systems: read, understand and then run /tmp/fix_nfs_on_maverick_amis.sh\n****\n"
end
