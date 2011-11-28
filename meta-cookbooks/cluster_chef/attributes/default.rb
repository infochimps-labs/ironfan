

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

#
# Dashboard
#

default[:cluster_chef][:thttpd][:port]             = 6789
default[:cluster_chef][:dashboard][:links]       ||= {}  # hash of name => app dashboard url
default[:cluster_chef][:dashboard][:run_state]     = :start

#
# Server Tuning
#
default[:server_tuning][:ulimit]  ||= Mash.new

#
#
# For a desktop machine, the defaults are [0, 50, 60]
# For a dedicated server, you may prefer  [1, 100, 5]
#

#
# If virtual memory requests exceed available physical memory,
#
# * 0 = heuristic
# * 1 = allow until actually OOM.
# * 2 = Don't overcommit. The total address space commit for the system is not
#       permitted to exceed swap + a percentage (the `overcommit_ratio`) of
#       physical RAM. Depending on the percentage you use, in most situations
#       this means a process will not be killed while accessing pages but will
#       receive errors on memory allocation as appropriate.
#       (http://linux-mm.org/OverCommitAccounting)
#
# Dedicated-purpose servers -- especially one that launch multiple unreflective
# JVMs (hello, Hadoop) or fork other processes (top of the morning, jenkins) --
# should set this to 1
#
default[:server_tuning][:overcommit_memory] = 1

#
# When overcommit_memory is set to 2, the committed address space is not
# permitted to exceed swap plus this percentage of physical RAM.
#
default[:server_tuning][:overcommit_ratio]  = 100

#
# How aggressive the kernel will swap memory pages.  Higher values will increase
# agressiveness, lower values decrease the amount of swap.
#
# Since dedicated servers prefer the process death of OOM to the machine-wide
# death of swap churn, make the machine be as agressive as possible.
#
default[:server_tuning][:swappiness]        = 5
