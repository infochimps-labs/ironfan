cluster_node_index  = (node[:cluster_node_index] || node[:ec2][:ami_launch_index]).to_i
all_cluster_volumes = data_bag_item('cluster_ebs_volumes', node[:cluster_name])    rescue nil
cluster_ebs_volumes = all_cluster_volumes[node[:cluster_role]][cluster_node_index] rescue nil

Chef::Log.info [node[:ec2][:ami_launch_index]].inspect
Chef::Log.info [cluster_node_index, node[:cluster_role], all_cluster_volumes].inspect
Chef::Log.info cluster_ebs_volumes.inspect

if cluster_ebs_volumes
  cluster_ebs_volumes.each do |conf|
    if File.exists?(conf['device'])
      directory conf['mount_point'] do
        recursive true
        owner( conf['owner'] || 'root' )
        group( conf['owner'] || 'root' )
      end
      mount conf['mount_point'] do
        fstype( conf['type'] || 'xfs' )
        device( conf['device'] )
        # To simply mount the volume: action[:mount]
        # To mount the volume and add it to fstab: action[:mount,:enable]. This
        #   can cause hellacious problems on reboot if the volume isn't attached.
        # To remove the mount from /etc/fst, action[:disable]
        action [:mount]
      end
    else
      Chef::Log.info "Before mounting, you must attach volume #{conf['volume_id']} to this instance #{node[:ec2][:instance_id]} at #{conf['device']}"
    end
  end
end
