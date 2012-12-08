module Ironfan
  class Provider
    class Ec2

      class ElasticIp < Ironfan::Provider::Resource
      	delegate :addresses, :associate_address, :allocation_id, 
            :allocation_id=, :destroy, :domain, :domain=, 
            :describe_addresses, :disassociate_address, :domain, :id,
            :network_interface_id, :network_interface_id=, :public_ip, 
            :public_ip=, :save, :server=, :server, :server_id, :server_id=,
        :to => :adaptee
 
        def self.shared?()              true;                               end
        def self.multiple?()            false;                              end
        def self.resource_type()        :elastic_ip;                        end
        def self.expected_ids(computer) [ computer.server.ec2.public_ip ];  end

        def name()                      adaptee.public_ip ;                 end

        # FIXME: This is very broken, but somehow works around the breakage
        def self.new(*args)
          x = super
          x.adaptee = args[0][:adaptee]
          x
        end

        def self.load!(cluster=nil)
          Ec2.connection.addresses.each do |eip|
            register eip
            Chef::Log.debug("Loaded #{eip}")
          end
          pp adaptee
        end
  
        end
      end
    end
  end
end
