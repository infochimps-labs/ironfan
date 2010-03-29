name 'nfs_client'
description 'mounts an nfs directory'

run_list *%w[
  ec2::filesystems
  nfs
  nfs::client
]

default_attributes({
    :nfs_mounts => {
      '/shared' => { :owner => 'root', :device => 'chef.infinitemonkeys.info:/mnt/shared' }
    },
  })


