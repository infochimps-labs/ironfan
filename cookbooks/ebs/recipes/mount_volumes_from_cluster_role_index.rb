log_cluster_volume_info('mount_volumes_from_cluster_role_index')

if cluster_ebs_volumes
  cluster_ebs_volumes.each do |conf|
    directory conf['mount_point'] do
      recursive true
      owner     conf['owner'] || 'root'
      group     conf['owner'] || 'root'
    end
    mount conf['mount_point'] do
      only_if{ File.exists?(conf['device']) }
      device    conf['device']
      fstype    conf['type'].blank? ? fstype_from_file_magic(conf['device']) : conf['type']
      options   conf['options'] || 'defaults'
      # To simply mount the volume: action[:mount]
      # To mount the volume and add it to fstab: action[:mount,:enable]. This
      #   can cause hellacious problems on reboot if the volume isn't attached.
      action    [:mount]
    end
  end
end
