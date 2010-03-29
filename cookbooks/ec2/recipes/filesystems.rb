if node[:ebs_volumes]
  node[:ebs_volumes].each do |name, conf|
    if File.exists?(conf[:device])
      mount conf[:mount_point] do
        fstype conf[:type]
        device conf[:device]
      end
    else
      Chef::Log.info "Before mounting, you must attach volume #{name} to this instance #{node[:ec2][:instance_id]} at #{conf[:device]}"
    end
  end
end