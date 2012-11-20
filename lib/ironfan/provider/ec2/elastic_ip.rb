module Ironfan
  class Provider
    class Ec2

      class ElasticIp < Ironfan::Provider::Resource
      	delegate :allocate, :associate, :describe, :to => :adaptee
      	field :domain,			String, 			:default =>  'standard'

      	:associate

      	def address(ip)

      	end

      	def attach(ip, timeout)

      	end

      	def detach(ip, timeout)

      	end
      end
    end
  end
end

# 'publicIp', 'domain'
# vpc use only = 'allocationId', 'associationId', 'instanceId', 'requestId'
