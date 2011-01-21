#
# NFS aspects for poolparty and chef
#

# Poolparty rules to make the node act as an NFS server.  The way this is set
# up, NFS server has open ports to each NFS client, but NFS clients don't
# necessarily have open access to each other.
def is_nfs_server settings
  has_role settings, "nfs_server"
  security_group 'nfs-client'
  security_group 'nfs-server' do
    authorize :group_name => 'nfs-client'
  end
end

# Poolparty rules to make the node act as an NFS server.
# Assigns the security group (thus gaining port access to the server)
# and stuffs in some chef attributes to mount the home drive
def is_nfs_client settings
  has_role settings, "nfs_client"
  security_group 'nfs-client'
end
