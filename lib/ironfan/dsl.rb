require 'ironfan/dsl/builder'
require 'ironfan/dsl/ec2'
require 'ironfan/dsl/role'

require 'ironfan/dsl/cloud'
require 'ironfan/dsl/volume'        # configure external and internal volumes

require 'ironfan/dsl/compute'       # base class for server attributes
require 'ironfan/dsl/server'        # realization of a specific facet
require 'ironfan/dsl/facet'         # similar machines within a cluster
require 'ironfan/dsl/cluster'       # group of machines with a common mission
