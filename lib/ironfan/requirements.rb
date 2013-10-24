# Gorillib core classes
require 'gorillib/builder'
require 'gorillib/resolution'

# Pre-declaration of class hierarchy
require 'ironfan/headers'

# DSL for cluster descriptions
require 'ironfan/dsl'
require 'ironfan/builder'

require 'ironfan/dsl/component'
require 'ironfan/dsl/compute'
require 'ironfan/dsl/server'
require 'ironfan/dsl/facet'
require 'ironfan/dsl/cluster'
require 'ironfan/dsl/realm'

require 'ironfan/dsl/role'
require 'ironfan/dsl/volume'

require 'ironfan/dsl/cloud'
require 'ironfan/dsl/ec2'
require 'ironfan/dsl/vsphere'
require 'ironfan/dsl/rds'


# Providers for specific resources
require 'ironfan/provider'

require 'ironfan/provider/chef'
require 'ironfan/provider/chef/client'
require 'ironfan/provider/chef/node'
require 'ironfan/provider/chef/role'

require 'ironfan/provider/ec2'
require 'ironfan/provider/ec2/ebs_volume'
require 'ironfan/provider/ec2/machine'
require 'ironfan/provider/ec2/keypair'
require 'ironfan/provider/ec2/placement_group'
require 'ironfan/provider/ec2/security_group'
require 'ironfan/provider/ec2/elastic_ip'
require 'ironfan/provider/ec2/elastic_load_balancer'
require 'ironfan/provider/ec2/iam_server_certificate'

require 'ironfan/provider/virtualbox'
require 'ironfan/provider/virtualbox/machine'

require 'ironfan/provider/vsphere'
require 'ironfan/provider/vsphere/machine'
require 'ironfan/provider/vsphere/keypair'

require 'ironfan/provider/rds'
require 'ironfan/provider/rds/machine'
require 'ironfan/provider/rds/security_group'

# Broker classes to coordinate DSL expectations and provider resources
require 'ironfan/broker'
require 'ironfan/broker/computer'
require 'ironfan/broker/drive'


# Calls that are slated to go away
require 'ironfan/deprecated'
