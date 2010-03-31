# function wait_for_mount {
#   mount=$1
#   device=$2
#
#   mkdir $mount
#
#   i=1
#   echo "Attempting to mount $device"
#   while true ; do
#     sleep 10
#     echo -n "$i "
#     i=$[$i+1]
#     mount -o defaults,noatime $device $mount || continue
#     echo " Mounted."
#     if $automount ; then
#       echo "$device $mount xfs defaults,noatime 0 0" >> /etc/fstab
#     fi
#     break;
#   done
# }

# function scaffold_ebs_hdfs {
#     # EBS_MAPPINGS is like "/ebs1,/dev/sdj;/ebs2,/dev/sdk"
#     DFS_NAME_DIR=''
#     FS_CHECKPOINT_DIR=''
#     DFS_DATA_DIR=''
#     for mapping in $(echo "$EBS_MAPPINGS" | tr ";" "\n"); do
#       # Split on the comma (see "Parameter Expansion" in the bash man page)
#       mount=${mapping%,*}
#       device=${mapping#*,}
#       wait_for_mount $mount $device
#       DFS_NAME_DIR=${DFS_NAME_DIR},"$mount/hadoop/hdfs/name"
#       FS_CHECKPOINT_DIR=${FS_CHECKPOINT_DIR},"$mount/hadoop/hdfs/secondary"
#       DFS_DATA_DIR=${DFS_DATA_DIR},"$mount/hadoop/hdfs/data"
#       FIRST_MOUNT=${FIRST_MOUNT-$mount}
#       make_hadoop_dirs $mount
#     done
#     # Remove leading commas
#     DFS_NAME_DIR=${DFS_NAME_DIR#?}
#     FS_CHECKPOINT_DIR=${FS_CHECKPOINT_DIR#?}
#     DFS_DATA_DIR=${DFS_DATA_DIR#?}
# }
