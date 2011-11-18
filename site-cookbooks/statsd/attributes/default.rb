
#
# Locations
#

default[:statsd][:install_dir]        = "/usr/src/statsd"

default[:groups]['statsd' ][:gid]  = 310

default[:statsd][:graphite][:port] = 2003
default[:statsd][:graphite][:addr] = "localhost"
default[:statsd][:port]            = 8125

default[:statsd][:cluster_name]    = node[:cluster_name]

#
# Install
#

default[:statsd][:git_repo]         = "https://github.com/etsy/statsd.git"

#
# Tunables
#

default[:statsd][:flush_interval]   = 10000 #milliseconds between flushes
