module Ironfan
  class Provider
    class Ec2

      class ElasticIp < Ironfan::Provider::Resource
      	delegate :public_ip, :allocation_id, :server_id, :network_interface_id,:domain, :initialize, :destroy, :server=, :server, :save,            :associate, :disassociate,  
        :to => :adaptee
      	
        def self.shared?()              true;           end
        def self.multiple?()            false;          end
        def self.resource_type()        :elastic_ip;    end
        def self.expected_ids(computer) [ computer.server.ec2.public_ip ]; end

        def name() public_ip; end
          
        def self.load!(cluster=nil)
          Ec2.connection.addresses.each do |eip|
            pp(eip.public_ip)
            remember new(:adaptee => eip)
            pp(eip.public_ip)
            Chef::Log.debug("Loaded #{eip}")
          end
          raise "hell"
        end

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
