name        'nfs_server'
description 'exports an nfs directory'

run_list *%w[
  nfs
  nfs::server
]

default_attributes({
    :nfs => { :exports => {
        '/home' => { :nfs_options => '*.internal(rw,no_root_squash,no_subtree_check)' },
      } },
  })
