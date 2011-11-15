default[:redis][:home_dir]       = "/usr/local/share/redis"
default[:redis][:addr]        = "0.0.0.0"
default[:redis][:port]           = "6379"
default[:redis][:pid_file]        = "/var/run/redis.pid"
default[:redis][:log_file]        = "/var/log/redis/redis.log"
default[:redis][:data_dir]       = "/var/lib/redis"
default[:redis][:dbfile]         = "dump.rdb"
default[:redis][:client_timeout] = "300"
default[:redis][:glueoutputbuf]  = "yes"

default[:redis][:install_url]    = 'http://redis.googlecode.com/files/redis-2.0.2.tar.gz'

default[:redis][:saves] = [["900", "1"], ["300", "10"], ["60", "10000"]]

default[:redis][:slave] = "no"
if node[:redis][:slave] == "yes"
  default[:redis][:master_server] = "redis-master." + domain
  default[:redis][:master_port] = "6379"
end

default[:redis][:shareobjects] = "no"
if node[:redis][:shareobjects] == "yes"
  default[:redis][:shareobjectspoolsize] = 1024
end
