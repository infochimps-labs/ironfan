module Ironfan
  class Provider
    class Ec2

      class ElasticIp < Ironfan::Provider::Resource
      	delegate :addresses, :associate_address, :allocation_id, 
            :allocation_id=, :destroy, :domain, :domain=, 
            :describe_addresses, :disassociate_address, :domain, :id,
            :network_interface_id, :network_interface_id=, :public_ip, 
            :public_ip=, :public_ip_address, :save, :server=, :server, :server_id, 
            :server_id=,
        :to => :adaptee
 
        def self.shared?()              true;                               end
        def self.multiple?()            false;                              end
        def self.resource_type()        :elastic_ip;                        end
        def self.expected_ids(computer) [ computer.server.ec2.elastic_ip ]; end
        def name()                      adaptee.public_ip ;                 end

        #
        # Discovery
        #

        def self.load!(cluster=nil)
          Ec2.connection.addresses.each do |eip|
            register eip
            Chef::Log.debug("Loaded #{eip}")

            # The rest of this definition shows relevant information when -VV
            #   is passed to knife and aids in troubleshooting any refusal to
            #   attach Elastic IPs
            Chef::Log.debug( "AWS domain: #{eip.domain}" )
            Chef::Log.debug( "available ip match: #{eip.public_ip}" )
            Chef::Log.debug( "----------------------" )
          end

          cluster.servers.each do |s|
            next if s.ec2.elastic_ip.nil?
            if recall? s.ec2.elastic_ip
              Chef::Log.debug( "Cluster elastic_ip matches #{s.ec2.elastic_ip}" )
            else
              Chef::Log.debug( "No matching Elastic IP for #{s.ec2.elastic_ip}" )
            end
          end

        end

        #
        # Manipulation
        #

        def self.save!(computer)
          return unless computer.created?
          elastic_ip = computer.server.ec2.elastic_ip
          Ironfan.step(computer.name, "associating Elastic IP #{elastic_ip}", :blue)
          Ironfan.unless_dry_run do
            Ironfan.safely do
              Ec2.connection.associate_address( computer.machine.id, elastic_ip )
            end
          end
        end

      end
    end
  end
end
