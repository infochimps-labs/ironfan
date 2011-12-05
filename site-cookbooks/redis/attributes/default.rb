#
# Locations
#

default[:redis][:conf_dir]          = "/etc/redis"
default[:redis][:log_dir]           = "/var/log/redis"
default[:redis][:data_dir]          = "/var/lib/redis"

default[:redis][:home_dir]          = "/usr/local/share/redis"
default[:redis][:pid_file]          = "/var/run/redis.pid"
default[:redis][:db_basename]       = "dump.rdb"

default[:redis ][:user]              = 'redis'
default[:users ]['redis'][:uid]      = 335
default[:groups]['redis'][:gid]      = 335

#
# Server
#

default[:redis][:server][:addr]     = "0.0.0.0"
default[:redis][:server][:port]     = "6379"

#
# Install
#

default[:redis][:version]           = "2.0.2"
default[:redis][:release_url]       = "http://redis.googlecode.com/files/redis-:version:.tar.gz"

#
# Tunables
#

default[:redis][:server][:timeout]  = "300"
default[:redis][:glueoutputbuf]     = "yes"

default[:redis][:saves]             = [["900", "1"], ["300", "10"], ["60", "10000"]]

default[:redis][:slave]             = "no"
if (node[:redis][:slave] == "yes")
  # TODO: replace with discovery
  default[:redis][:master_server]   = "redis-master." + domain
  default[:redis][:master_port]     = "6379"
end

default[:redis][:shareobjects]      = "no"
if (node[:redis][:shareobjects] == "yes")
  default[:redis][:shareobjectspoolsize] = 1024
end
