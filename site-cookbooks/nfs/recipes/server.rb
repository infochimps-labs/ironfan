#
# Cookbook Name::       nfs
# Description::         NFS server: exports directories via NFS; announces using metachef discovery.
# Recipe::              server
# Author::              37signals
#
# Copyright 2011, 37signals
#
# (no license specified)
#

unless File.exists?('/etc/init.d/nfs-kernel-server')
  Chef::Log.warn "\n\n****\nYou may have to restart the machine after nfs-kernel-server is installed\n****\n"
end

package "nfs-kernel-server"

if node[:nfs][:exports]
  #
  # FIXME: we should announce each export on its own, along with realm
  #
  hsh = Mash.new(node[:nfs][:exports].to_hash)
  hsh[:realm] ||= 'all'
  announce(:nfs, :server, hsh)

  service "nfs-kernel-server" do
    action [ :enable, :start ]
    running true
    supports :status => true, :restart => true
  end

  template "/etc/exports" do
    source      "exports.erb"
    owner       "root"
    group       "root"
    mode        "0644"
    notifies    :restart, resources(:service => "nfs-kernel-server")
  end
else
  Chef::Log.warn "You included the NFS server recipe without defining nfs exports: set node[:nfs][:exports]."
end

#
# For problems starting NFS server on ubuntu maverick systems: read, understand
# and then run /tmp/fix_nfs_on_maverick_amis.sh
#
if (node[:lsb][:release].to_f == 10.10)
  template "/tmp/fix_nfs_on_maverick_amis.sh" do
    source "fix_nfs_on_maverick_amis.sh"
    owner "root"
    group "root"
    mode 0700
  end
  if (`service nfs-kernel-server status` =~ /not running/)
    Chef::Log.warn "\n\n****\nFor problems starting NFS server on ubuntu maverick systems: read, understand and then run /tmp/fix_nfs_on_maverick_amis.sh\n****\n"
  end
end
