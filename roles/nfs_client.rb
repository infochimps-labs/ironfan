name        'nfs_client'
description 'mounts an nfs directory'

run_list *%w[
  nfs
  nfs::client
]

# Attributes applied if the node doesn't have it set already.
default_attributes({
    :nfs => {
      :mounts => [
        ['/home', { :owner => 'root', :remote_path => "/home" }]
      ],
    }
  })


