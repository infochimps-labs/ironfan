
#
# Dashboard
#

default[:cluster_chef][:thttpd][:port]             = 6789
default[:cluster_chef][:dashboard][:links]       ||= {}  # hash of name => app dashboard url
default[:cluster_chef][:dashboard][:run_state]     = :start
