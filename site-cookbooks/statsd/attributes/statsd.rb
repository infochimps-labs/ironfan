
default[:statsd][:cluster_name] = node[:cluster_name]

default[:statsd][:git_uri] = "https://github.com/etsy/statsd.git"
default[:statsd][:src_path] = "/usr/src/statsd"

default[:statsd][:graphite][:port] = 2003
default[:statsd][:graphite][:host] = "localhost"

default[:statsd][:port] = 8125
