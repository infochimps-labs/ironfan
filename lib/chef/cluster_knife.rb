require 'chef/knife'
require 'chef/knife/bootstrap'
require 'chef/knife/ssh'
require 'gorillib/model/serialization'
require 'yaml'

require 'chef/knife/ironfan_knife_common'
require 'chef/knife/ironfan_script'

class Chef
  class Knife
    autoload :ClusterBootstrap, 'chef/knife/cluster_bootstrap'
    autoload :ClusterDiff,      'chef/knife/cluster_diff'
    autoload :ClusterKick,      'chef/knife/cluster_kick'
    autoload :ClusterKill,      'chef/knife/cluster_kill'
    autoload :ClusterLaunch,    'chef/knife/cluster_launch'
    autoload :ClusterList,      'chef/knife/cluster_list'    
    autoload :ClusterProxy,     'chef/knife/cluster_proxy'
    autoload :ClusterPry,       'chef/knife/cluster_pry'
    autoload :ClusterShow,      'chef/knife/cluster_show'
    autoload :ClusterSsh,       'chef/knife/cluster_ssh'
    autoload :ClusterStart,     'chef/knife/cluster_start'
    autoload :ClusterStop,      'chef/knife/cluster_stop'
    autoload :ClusterSync,      'chef/knife/cluster_sync'
  end
end
