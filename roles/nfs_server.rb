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
    :firewall => {
      :port_scan_portmap => {
        :window => 20,
        :max_conns => 15,
        :port => 111
      },
      :port_scan_nfsd => {
        :window => 20,
        :max_conns => 15,
        :port => 2049
      },
      :port_scan_mountd => {
        :window => 20,
        :max_conns => 15,
        :port => 45560
      },
      :port_scan_statd => {
        :window => 20,
        :max_conns => 15,
        :port => 56785
      }
    }
  })
