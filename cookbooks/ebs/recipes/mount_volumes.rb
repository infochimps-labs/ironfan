if node[:ebs_volumes]
  node[:ebs_volumes].each do |name, conf|
    if File.exists?(conf[:device])
      directory conf[:mount_point] do
        recursive true
        owner conf[:owner]
        group conf[:owner]
      end
      mount conf[:mount_point] do
        fstype conf[:type]
        device conf[:device]
        # mount and add to fstab. set to 'disable' to remove it
        action [:enable, :mount]
      end
    else
      Chef::Log.info "Before mounting, you must attach volume #{name} to this instance #{node[:ec2][:instance_id]} at #{conf[:device]}"
    end
  end
end
