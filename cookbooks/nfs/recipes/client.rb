package "nfs-common"

if node[:nfs_mounts]
  node[:nfs_mounts].each do |target, config|
    directory target do
      recursive true
      owner (config[:owner]||'root')
      group (config[:owner]||'root')
    end
    mount target do
      fstype "nfs"
      options %w(rw,soft,intr)
      options %w(rsize=32768,wsize=32768,bg,nfsvers=3,intr,tcp)
      nfs_server_info = data_bag_item('servers_info', 'nfs_server')
      nfs_server_ip   = nfs_server_info ? nfs_server_info["private_ip"] : node[:nfs][:server]
      device_path = config[:device] ? config[:device] : "#{nfs_server_ip}:#{config[:remote_path]}"
      device device_path
      dump 0
      pass 0
      # To simply mount the volume: action[:mount]
      # To mount the volume and add it to fstab: action[:mount,:enable] -- but be aware this can cause problems on reboot if the host can't be reached.
      # To remove the mount from /etc/fst, action[:disable]
      action [:mount]
    end
  end
else
  Chef::Log.warn "You included the NFS client recipe without defining nfs mounts."
end
