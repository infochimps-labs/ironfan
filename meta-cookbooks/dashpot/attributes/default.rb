
# hash, name => app dashboard url
# add yours using add_dashboard_link
default[:dashpot][:links]     ||= Mash.new

#
# Location
#

default[:dashpot][:conf_dir] = '/etc/dashpot'
default[:dashpot][:log_dir]  = '/var/log/dashpot'
default[:dashpot][:home_dir] = '/var/lib/dashpot'

#
# Dashboard service -- lightweight THTTPD daemon
#

default[:dashpot][:port]        = 6789
default[:dashpot][:run_state]   = :start

default[:dashpot][:user]     = 'root'
