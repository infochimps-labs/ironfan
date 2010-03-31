name        'nfs_client'
description 'mounts an nfs directory'

run_list *%w[
  nfs
  nfs::client
]


