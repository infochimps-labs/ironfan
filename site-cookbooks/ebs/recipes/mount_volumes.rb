if node[:ebs_volumes]
  node[:ebs_volumes].each do |name, conf|
    if File.exists?(conf[:device])
      directory conf[:mount_point] do
        recursive true
        owner( conf[:owner] || 'root' )
        group( conf[:owner] || 'root' )
      end
      mount conf[:mount_point] do
        fstype( conf[:type] || 'xfs' )
        device( conf[:device] )
        # To simply mount the volumen: action[:mount]
        # To mount the volume and add it to fstab: action[:mount,:enable]. This
        #   can cause hellacious problems on reboot if the volume isn't attached.
        # To remove the mount from /etc/fst, action[:disable]
        action [:mount]
      end
    else
      Chef::Log.info "Before mounting, you must attach volume #{name} to this instance #{node[:ec2][:instance_id]} at #{conf[:device]}"
    end
  end
end
