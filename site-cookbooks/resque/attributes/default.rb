default[:resque][:home_dir]                   = '/data/db/resque'
default[:resque][:log_dir]               = '/data/db/resque/log'
default[:resque][:tmp_dir]               = '/data/db/resque/tmp'
default[:resque][:data_dir]                 = "/data/db/resque/data"
default[:resque][:swapdir]               = "/data/db/resque/swap"
default[:resque][:conf_dir]              = '/etc/resque'
default[:resque][:dbfile]                = "resque_queue.rdb"

default[:resque][:cluster_name]          = node[:cluster_name]

default[:resque][:namespace]             = node[:cluster_name]

default[:resque][:user]                  = 'resque'
default[:resque][:group]                 = 'resque'

default[:resque][:queue_address]         = node[:cloud][:private_ips].first
default[:resque][:queue_port]            = "6388"
default[:resque][:dashboard_port]        = "6389"

default[:resque][:redis_client_timeout]  = "300"
default[:resque][:redis_glueoutputbuf]   = "yes"
default[:resque][:redis_vm_enabled]      = "yes"
default[:resque][:redis_vm_max_memory]   = "128m"     # 512m
default[:resque][:redis_vm_pages]        = "16777216" # 134217728

default[:resque][:redis_saves]           = [["900", "1"], ["300", "10"], ["60", "10000"]]
default[:resque][:redis_slave]           = "no"
# default[:resque][:redis_master_server] = "redis-master." + domain
# default[:resque][:redis_master_port]   = "6388"
default[:resque][:app_env]               = 'production'
