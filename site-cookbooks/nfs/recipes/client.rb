#
# Cookbook Name::       nfs
# Description::         NFS client: uses metachef to discover its server, and mounts the corresponding NFS directory
# Recipe::              client
# Author::              37signals
#
# Copyright 2011, 37signals
#
# (no license specified)
#

package "nfs-common"

bash "modprobe nfs" do
  user          'root'
  code          "modprobe nfs"
  not_if("cat /proc/filesystems | grep -q nfs")
end

nfs_server_ip = discover(:nfs, :server).private_ip rescue nil

if nfs_server_ip.nil?
  Chef::Log.error("***************")
  Chef::Log.error("Can't find the NFS server: check that chef ran successfully on that machine. You may need to restart it after initial install.")
  Chef::Log.error("***************")
else

  if node[:nfs] && node[:nfs][:mounts]
    node[:nfs][:mounts].each do |target, config|
      mount target do
        fstype      "nfs"
        options     %w(rw,soft,intr,nfsvers=3)
        device      (config[:device] || "#{nfs_server_ip}:#{config[:remote_path]}")
        dump        0
        pass        0
        action      [:mount]
      end
    end
  else
    Chef::Log.warn "You included the NFS client recipe without defining nfs mounts."
  end

end
