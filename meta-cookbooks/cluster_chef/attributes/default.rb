

default[:cluster_chef][:conf_dir] = '/etc/cluster_chef'
default[:cluster_chef][:log_dir]  = '/var/log/cluster_chef'
default[:cluster_chef][:home_dir] = '/etc/cluster_chef'

default[:cluster_chef][:user]     = 'root'

# Request user account properties here.
default[:users]['root'][:primary_group] = value_for_platform(
  "openbsd"   => { "default" => "wheel" },
  "freebsd"   => { "default" => "wheel" },
  "mac_os_x"  => { "default" => "wheel" },
  "default"   => "root"
)

# Placeholder --
default[:groups]


#
# Dashboard
#

default[:cluster_chef][:thttpd][:port] = 6789
default[:cluster_chef][:dashboard][:links] = {}  # hash of name => app dashboard url
#
# Server Tuning
#
default[:server_tuning][:ulimit]  = Mash.new
