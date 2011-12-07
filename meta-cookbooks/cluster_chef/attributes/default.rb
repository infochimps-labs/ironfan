
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

default[:announces] ||= Mash.new

default[:discovers] ||= Mash.new
