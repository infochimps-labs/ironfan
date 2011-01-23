package "nfs-common"

if node[:nfs] && node[:nfs][:mounts]
  node[:nfs][:mounts].each do |target, config|
    directory target do
      recursive true
      owner (config[:owner]||'root')
      group (config[:owner]||'root')
    end
    mount target do
      fstype "nfs"
      options %w(rw,soft,intr)
      # options %w(rsize=32768,wsize=32768,bg,nfsvers=3,intr,tcp)
      device config[:device] ? config[:device] : "#{provider_private_ip('nfs_server')}:#{config[:remote_path]}"
      dump 0
      pass 0
      # To simply mount the volume: action[:mount]
      # To mount the volume and add it to fstab: action[:mount,:enable] -- but be aware this can cause problems on reboot if the host can't be reached.
      # To remove the mount from /etc/fstab, use action[:disable]
      action [:mount]
    end
  end
else
  Chef::Log.warn "You included the NFS client recipe without defining nfs mounts."
end
