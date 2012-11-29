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
 
        def self.shared?()              true;          end
        def self.multiple?()            false;          end
        def self.resource_type()        :elastic_ip;    end
        def self.expected_ids(computer) [ computer.server.ec2.public_ip ]; end

        def name()                      adaptee.public_ip ;     end

        Ec2.connection.servers.each do |m|
          pp m.id, m.state, m.public_ip_address if m.state != "terminated"
        end

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
        end

        def self.attach()
          Ec2.connection.addresses.each do |eip|
            eip.associate_address(eip.id, adaptee.public_ip) unless eip.public_ip_address.nil?
        end
          
        end
      end
    end
  end
end
