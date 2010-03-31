name 'nfs_client'
description 'mounts an nfs directory'

run_list *%w[
  ec2::filesystems
  nfs
  nfs::client
]

default_attributes({
    :nfs => {
      :master => '10.162.143.95',
    }
  })


