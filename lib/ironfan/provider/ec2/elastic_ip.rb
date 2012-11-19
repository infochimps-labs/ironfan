module Ironfan
  class Provider
    class Ec2

      class ElasticIp < Ironfan::Provider::Resource
      	delegate :allocate_address, :associate_address, :describe_addresses
      	:to => :adaptee
      	field :domain,			String, 			:default =>  'standard'
      end
    end
  end
end

# 'publicIp', 'domain'
# vpc use only = 'allocationId', 'associationId', 'instanceId', 'requestId'

