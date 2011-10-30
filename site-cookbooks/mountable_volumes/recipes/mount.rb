if mountable_volumes
  mountable_volumes.each do |name, conf|

    if File.exists?(conf[:device])
      directory conf[:mount_point] do
        recursive true
        owner( conf[:owner] || 'root' )
        group( conf[:owner] || 'root' )
      end

      mount conf[:mount_point] do
        only_if{ File.exists?(conf['device']) }
        device    conf['device']
        fstype    conf['type'] || fstype_from_file_magic(conf['device'])
        options   conf['options'] || 'defaults'
        # To simply mount the volume: action[:mount]
        # To mount the volume and add it to fstab: action[:mount,:enable]. This
        #   can cause hellacious problems on reboot if the volume isn't attached.
        action    [:mount]
      end
    else
      Chef::Log.info "Before mounting, you must attach volume #{name} to this instance #{node[:ec2][:instance_id]} at #{conf[:device]}"
    end
    
  end
end
