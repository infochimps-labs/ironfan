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

        def self.expected_ids(computer)
          [ computer.server.ec2.elastic_ip ]
        end

        def name()                      adaptee.public_ip ;                 end

        # FIXME: This is very broken, but somehow works around the breakage
        def self.new(*args)
          x = super
          x.adaptee = args[0][:adaptee]
          x
        end

        #
        # Discovery
        #

        def self.load!(cluster=nil, machine)
          Ec2.connection.addresses.each do |eip|
            register eip
            Chef::Log.debug("Loaded #{eip}")
          # The rest of this definition shows relevant information when -VV is passed to knife and aids in troubleshooting any refusal to attach Elastic IPs
            machine.facets.each do |f| 
              unless f.servers[0].clouds[:ec2].elastic_ip.nil? or eip.domain == "vpc"
                if eip.domain == "standard" and eip.public_ip == f.servers[0].clouds[:ec2].elastic_ip
                  Chef::Log.debug( "AWS domain: #{eip.domain}" )
                  Chef::Log.debug( "available ip match: #{eip.public_ip}" )
                  Chef::Log.debug( "----------------------" )
                end
              end
              unless eip.public_ip.nil? 
                if eip.domain == "standard"
                  if eip.public_ip == f.servers[0].clouds[:ec2].elastic_ip
                    unless f.servers[0].clouds[:ec2].elastic_ip.nil?
                      Chef::Log.debug( "ip given by cluster definition: #{f.servers[0].clouds[:ec2].elastic_ip}" )
                    else
                      Chef::Log.debug( "No matching Elastic IP available to your account." )
                    end
                  end
                end
              end
            end
          end
        end

        #
        # Manipulation
        #

        def self.save!(computer)
          return unless computer.machine?
          elastic_ip = computer.server.cloud(:ec2).elastic_ip
          return unless computer.created?
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
