module Ironfan
  class Provider
    class Ec2

      class ElasticIp < Ironfan::Provider::Resource
      	delegate :allocate_address, :associate_address, :describe_addresses
      	field :domain,			Ironfan::DSL::Compute
      end
    end
  end
end

# 'publicIp', 'domain'
# vpc use only = 'allocationId', 'associationId', 'instanceId', 'requestId'

