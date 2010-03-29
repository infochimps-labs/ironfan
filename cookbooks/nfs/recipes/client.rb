package "nfs-common"

if node[:nfs_mounts]
  node[:nfs_mounts].each do |target, config|
    directory target do
      recursive true
      owner config[:owner]
      group config[:owner]
    end
    mount target do
      fstype "nfs"
      options %w(rw,soft,intr)
      device config[:device]
      dump 0
      pass 0
      # mount and add to fstab. set to 'disable' to remove it
      action [:enable, :mount]
    end
  end
else
  Chef::Log.warn "You included the NFS client recipe without defining nfs mounts."
end