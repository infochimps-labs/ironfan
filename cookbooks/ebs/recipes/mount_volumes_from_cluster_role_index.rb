cluster_node_index  = (node[:cluster_node_index] || node[:ec2][:ami_launch_index]).to_i
all_cluster_volumes = data_bag_item('cluster_ebs_volumes', node[:cluster_name])    rescue nil

if all_cluster_volumes
  cluster_ebs_volumes = all_cluster_volumes[node[:cluster_role]][cluster_node_index] rescue []
  cluster_ebs_volumes.each do |name, conf|
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
