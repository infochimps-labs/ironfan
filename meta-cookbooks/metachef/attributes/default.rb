
default[:metachef][:conf_dir] = '/etc/metachef'
default[:metachef][:log_dir]  = '/var/log/metachef'
default[:metachef][:home_dir] = '/etc/metachef'

default[:metachef][:user]     = 'root'

# Request user account properties here.
default[:users]['root'][:primary_group] = value_for_platform(
  "openbsd"   => { "default" => "wheel" },
  "freebsd"   => { "default" => "wheel" },
  "mac_os_x"  => { "default" => "wheel" },
  "default"   => "root"
)

default[:announces] ||= Mash.new

default[:discovers] ||= Mash.new
