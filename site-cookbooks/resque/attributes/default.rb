
#
# Locations
#

default[:resque][:home_dir]             = '/data/db/resque'
default[:resque][:conf_dir]             = '/etc/resque'
default[:resque][:log_dir]              = '/var/log/resque'
default[:resque][:pid_dir]              = '/var/run/resque'

default[:resque][:tmp_dir]              = '/data/db/resque/tmp'
default[:resque][:data_dir]             = '/data/db/resque/data'
default[:resque][:journal_dir]          = '/data/db/resque/swap'

default[:resque][:db_basename]          = 'resque_queue.rdb'

default[:resque][:user]                 = 'resque'
default[:resque][:group]                = 'resque'
default[:users ]['resque' ][:uid]       = 336
default[:groups]['resque' ][:gid]       = 336

default[:resque][:namespace]            = node[:cluster_name]

default[:resque][:redis][:server][:addr] = '0.0.0.0'
default[:resque][:redis][:server][:port] = '6388'
default[:resque][:dashboard][:port]      = '6389'

default[:resque][:redis    ][:run_state] = :start
default[:resque][:dashboard][:run_state] = :start

default[:resque][:app_env]              = 'production'
