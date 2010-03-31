# TODO -- better separation of poolparty, chef and static settings.

# Poolparty definitions for a generic node.
def is_generic_node
  using :ec2
  availability_zones ['us-west-1a']
  instance_type      'm1.small'
  block_device_mapping([
      { :device_name => '/dev/sda1', :ebs_volume_size => 15, :ebs_delete_on_termination => false },
      { :device_name => '/dev/sdc',  :virtual_name => 'ephemeral0' },
    ])
  keypair        POOL_NAME, File.join(ENV['HOME'], '.poolparty')
  instance_initiated_shutdown_behavior 'stop'
end

# Poolparty rules to make the node act as a chef server
def is_chef_server
  security_group 'chef-server' do
    authorize :from_port => 22,  :to_port => 22
    authorize :from_port => 80,  :to_port => 80
    authorize :from_port => 4000,  :to_port => 4000  # chef-server-api
    authorize :from_port => 4040,  :to_port => 4040  # chef-server-webui
  end
end

# Poolparty rules to make the node act as a chef client
def is_chef_client
  security_group 'chef-client' do
    authorize :from_port => 22, :to_port => 22
    authorize :group_name => 'chef-server'
  end
end

# Poolparty rules to make the node act as an NFS server.  The way this is set
# up, NFS server has open ports to each NFS client, but NFS clients don't
# necessarily have open access to each other.
def is_nfs_server
  security_group 'nfs-server' do
    authorize :group_name => 'nfs-client'
  end
end

# Poolparty rules to make the node act as an NFS server.
# Assigns the security group (thus gaining port access to the server)
# and stuffs in some chef attributes to mount the home drive
def is_nfs_client attributes
  security_group 'nfs-client'
  attributes.merge!(:nfs_mounts => [ ['/home', { :owner => 'root', :remote_path => "/home" } ], ])
end

# Poolparty rules to make the node act as part of a cluster.
# Assigns security group named after the cluster (eg 'clyde') and after the
# cluster-role (eg 'clyde-master')
def is_hadoop_node
  security_group POOL_NAME do
    authorize :group_name => POOL_NAME
  end
  security_group do
    authorize :from_port => 22,  :to_port => 22
    authorize :from_port => 80,  :to_port => 80
  end
end

# Poolparty rules to make the node act as a worker in a hadoop cluster It looks
# up the master node's private IP address and passes that to the chef
# attributes.
def is_hadoop_worker attributes
  master_private_ip   = pool.clouds['master'].nodes.first.private_ip rescue nil
  if master_private_ip
    attributes.merge!(
      :hadoop => {
        :jobtracker_hostname => master_private_ip,
        :namenode_hostname   => master_private_ip, } )
  end
end
