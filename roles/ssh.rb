name        'ssh'
description 'Role showing node is ssh-able and adds iptables'

run_list *%w[
  firewall::port_scan
  ]


#
# Note: you must explicitly include the firewall recipe
#
default_attributes(
  {
    :firewall => { :port_scan => {
        :ssh => { :port => 111, :window => 20, :max_conns => 15 },
    } }
  })
