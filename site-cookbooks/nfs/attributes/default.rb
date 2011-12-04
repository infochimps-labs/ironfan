default[:nfs][:exports] = Mash.new

default[:nfs][:portmap_port] =   111
default[:nfs][:nfsd_port]    =  2049
default[:nfs][:mountd_port]  = 45560
default[:nfs][:statd_port]   = 56785

default[:nfs][:mounts] = [
  ['/home', { :owner => 'root', :remote_path => "/home" } ],
]

default[:firewall][:port_scan][:portmap] = { :port =>   111, :window => 20, :max_conns => 15, }
default[:firewall][:port_scan][:nfsd]    = { :port =>  2049, :window => 20, :max_conns => 15, }
default[:firewall][:port_scan][:mountd]  = { :port => 45560, :window => 20, :max_conns => 15, }
default[:firewall][:port_scan][:statd]   = { :port => 56785, :window => 20, :max_conns => 15, }
