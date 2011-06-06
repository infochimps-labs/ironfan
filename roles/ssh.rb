name        'ssh'
description 'Role showing node is ssh-able and adds iptables'

run_list *%w[
  firewall::port_scan
  ]


# Attributes applied if the node doesn't have it set already.
default_attributes({
                     :firewall => {
                       :port_scan_ssh => {
                         :window => 5,
                         :max_conns => 20,
                         :port => 22
                       }
                     }
                   })
