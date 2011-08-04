# Run this prior to setup/install of elasticsearch or nginx

package 'mdadm'

if node[:elasticsearch][:raid][:use_raid]

  mount "/mnt" do
    device "/dev/sdb"
    action [:umount, :disable]
  end
  
  mdadm "/dev/md0" do
    devices node[:elasticsearch][:raid][:devices]
    level 0
    action [:create, :assemble]
  end
  
  script "format_md0_xfs" do
    interpreter "bash"
    user "root"
    code <<-EOH
    if (! (file -s /dev/md0 | grep XFS) ); then
        mkfs.xfs -f /dev/md0
    fi
    # Returns success iff the drive is formatted XFS
    file -s /dev/md0 | grep XFS
    EOH
  end
  
  mount "/mnt" do
    device "/dev/md0"
    fstype "xfs"
    options "nobootwait,comment=cloudconfig"
    action [:mount, :enable]
  end

end
