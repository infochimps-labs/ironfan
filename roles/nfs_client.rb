name        'nfs_client'
description 'mounts an nfs directory'

run_list *%w[
  ec2::filesystems
  nfs
  nfs::client
]


