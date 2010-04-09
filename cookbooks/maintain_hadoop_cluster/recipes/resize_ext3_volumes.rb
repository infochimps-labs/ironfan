#
# Resize ext-formatted ebs volumes
#

if cluster_ebs_volumes
  cluster_ebs_volumes.each do |vol_info|
    mount_point = vol_info['mount_point']
    dev         = vol_info['device']
    bash 'resize_ext3_volumes' do
      only_if{ fstype_from_file_magic(dev) == 'ext3' }
      script <<EOF
    for foo in datanode tasktracker ; do sudo service hadoop-0.20-$foo stop ; done
    umount #{dev}
    sleep 2
    e2fsck -f -p #{dev} && resize2fs -p #{dev} && tune2fs -l #{dev} && mount #{dev} #{mount_point} && echo -e "YAY! #{dev} is resized"
EOF
    end
  end
end
