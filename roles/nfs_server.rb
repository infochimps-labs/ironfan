name 'nfs_server'
description 'exports an nfs directory'

run_list *%w[
  ec2::filesystems
  nfs
  nfs::server
]

default_attributes({
    :nfs => { :exports => {
        '/mnt/shared' => { :nfs_options => '*.internal(rw,no_root_squash,no_subtree_check)' },
      } },
  })
