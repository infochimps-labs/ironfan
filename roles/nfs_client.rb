name 'nfs_client'
description 'mounts an nfs directory'

run_list *%w[
  ec2::filesystems
  nfs
  nfs::client
]

override_attributes({
    :nfs_mounts => [
      ['/home', { :owner => 'root', :device => '10.162.143.95:/home' } ],
    ],
  })


