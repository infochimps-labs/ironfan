module Ironfan
  class Provider
    class Ec2

      class ElasticIp < Ironfan::Provider::Resource
      	delegate :addresses, :associate_address, :allocation_id,
            :allocation_id=, :allocate_address, :auto_elastic_ip, :destroy,
            :domain, :domain=, :describe_addresses, :disassociate_address,
            :domain, :id, :network_interface_id, :network_interface_id=,
            :public_ip, :public_ip=, :public_ip_address, :save, :server=,
            :server, :server_id, :server_id=,
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

            # The rest of this definition shows relevant information when -VV
            #   is passed to knife and aids in troubleshooting any refusal to
            #   attach Elastic IPs
            Chef::Log.debug( "AWS domain: #{eip.domain}" )
            if eip.public_ip.nil?
              Chef::Log.debug( "no Elastic IPs currently allocated" )
            else
              Chef::Log.debug( "available ip match: #{eip.public_ip}" )
              Chef::Log.debug( "available allocation_id match: #{eip.allocation_id}" )
            end
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
          return unless elastic_ip = computer.server.ec2.elastic_ip
          return unless recall? elastic_ip
          # also, in the case of VPC Elastic IPs, can discover and use allocation_id to attach a VPC Elastic IP.
          return unless computer.server.ec2.methods.include?(:elastic_ip)
          if ( computer.server.ec2.elastic_ip.nil? and cloud.vpc.nil? )
            # First,  :elastic_ip is set, no address is currently allocated for this connection's owner
            # NOTE: We cannot specify an address to create, but after a reload we can then load the first available.
            if computer.server.addresses.nil?
              Ec2.connection.allocate_address
              load!
              elastic_ip = computer.server.addresses.first.public_ip
              Chef::Log.debug( "allocating new Elastic IP address" )
            else
              # Second, :elastic_ip is set, has an address available to use but has no set value available in facet definition.
              elastic_ip = computer.server.addresses.first.public_ip
              Chef::Log.debug( "using first available Elastic IP address" )
            end
          elsif ( !computer.server.ec2.elastic_ip.nil? or cloud.vpc.nil? )
            # Third,  :elastic_ip is set, has an address available to use, has a set value in facet definition and is not VPC.
            elastic_ip = computer.server.ec2.elastic_ip
            Chef::Log.debug( "using requested Elastic IP address" )
          elsif ( computer.server.ec2.elastic_ip.nil? and !cloud.vpc.nil? )
            # Fourth, is exactly like Third but on a VPC domain. (this is functionaility for attaching VPC Elastic IPS)
            allocation_id = computer.server.ec2.allocation_id
            Chef::Log.debug( "using Elastic IP address matched to given Allocation ID" )
          else
            ui.fatal("You have set both :elastic_ip and :auto_elastic_ip in your facet definition; which are mutually exclusive.")
          end
          Ironfan.step(computer.name, "associating Elastic IP #{elastic_ip}", :blue)
          Ironfan.unless_dry_run do
            Ironfan.safely do
              vpc           = computer.server.ec2.vpc
              allocation_id = recall(elastic_ip).allocation_id
              raise "#{elastic_ip} is only for non-VPC instances" if vpc and allocation_id.nil?
              raise "#{elastic_ip} is only for VPC instances"     if vpc.nil? and allocation_id
              Ec2.connection.associate_address( computer.machine.id, elastic_ip, nil, allocation_id )
            end
          end
        end

      end
    end
  end
end
