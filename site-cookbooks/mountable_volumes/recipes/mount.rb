mountable_volumes.each do |vol_name, vol|
  
  if File.exists?(vol['device'])
    directory vol['mount_point'] do
      recursive true
      owner( vol['owner'] || 'root' )
      group( vol['owner'] || 'root' )
    end

    #
    # If you mount multiple EBS volumes from the same snapshot, you may get an
    #   'XFS: Filesystem xvdk has duplicate UUID - can't mount'
    # error (check `sudo dmesg | tail`).
    #
    # If so, read http://linux-tips.org/article/50/xfs-filesystem-has-duplicate-uuid-problem
    #
    
    mount vol['mount_point'] do
      only_if{ File.exists?(vol['device']) }
      device    vol['device']
      fstype    vol['fs_type']       || fstype_from_file_magic(vol['device'])
      options   vol['mount_options'] || 'defaults'
      action    [:mount]
    end
  else
    Chef::Log.info "Before mounting, you must attach volume #{vol_name} to this instance (#{node[:ec2][:instance_id]}) at #{vol['device']}"
  end
  
end
