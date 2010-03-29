
# # Look for a mount that must be named "/mnt/home" (defined in
# # ec2-storage-YOURCLUSTER.json).
# function mount_home_volume {
#   if [[ $EBS_MAPPINGS =~ '/mnt/home,' ]] ; then
#     # Extract and strip the mapping from the EBS_MAPPINGS
#     mapping=`echo $EBS_MAPPINGS | sed 's|.*\(/mnt/home,[^;]*\);*.*|\1|'`
#     EBS_MAPPINGS=`echo $EBS_MAPPINGS | sed 's|/mnt/home,[^;]*;*||'`
#     echo "Mounting $mapping but not using it for HDFS"
#     mount=${mapping%,*}
#     device=${mapping#*,}
#     wait_for_mount $mount $device
#   fi
# }

# function install_nfs {
#   if which dpkg &> /dev/null; then
#     if $IS_MASTER; then
#       apt-get -y install nfs-kernel-server
#     fi
#     apt-get -y install nfs-common
#   elif which rpm &> /dev/null; then
#     echo "!!!! Don't know how to install nfs on RPM yet !!!!"
#     # if $IS_MASTER; then
#     #   yum install -y
#     # fi
#     # yum install nfs-utils nfs-utils-lib portmap system-config-nfs
#   fi
# }
#
# # Sets up an NFS-shared home directory.
# #
# # The actual files live in /mnt/home on master.  You probably want /mnt/home to
# # live on an EBS volume, with a line in ec2-storage-YOURCLUSTER.json like
# #  "master": [ [
# #    { "device": "/dev/sdh", "mount_point": "/mnt/home",  "volume_id": "vol-01234567" }
# #    ....
# # On slaves, home drives are NFS-mounted from master to /mnt/home
# function configure_nfs {
#   if $IS_MASTER; then
#     grep -q '/mnt/home' /etc/exports || ( echo "/mnt/home  *.internal(rw,no_root_squash,no_subtree_check)" >> /etc/exports )
#   else
#     # slaves get /mnt/home from master
#     mv  /etc/fstab /etc/fstab.before_nfs_home
#     cat /etc/fstab.before_nfs_home | grep -v '/mnt/home'       >  /etc/fstab
#     echo "${MASTER_HOST}:/mnt/home  /mnt/home    nfs  rw  0 0" >> /etc/fstab
#   fi
#   rmdir    /home 2>/dev/null
#   mkdir -p /var/lib/nfs/rpc_pipefs
#   mkdir -p /mnt/home
#   ln -nfsT /mnt/home /home
# }
#
# function start_nfs {
#   if $IS_MASTER; then
#     /etc/init.d/nfs-kernel-server restart
#     /etc/init.d/nfs-common restart
#   else
#     /etc/init.d/nfs-common restart
#     mount /mnt/home
#   fi
# }
