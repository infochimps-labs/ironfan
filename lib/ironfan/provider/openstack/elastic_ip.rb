module Ironfan
  class Provider
    class OpenStack
      class ElasticIp < Ironfan::Provider::Resource
      	delegate :addresses, :associate_address, 
            :allocate_address, :auto_elastic_ip, :destroy,
            :domain, :domain=, :describe_addresses, :disassociate_address,
            :domain, :id, :network_interface_id, :network_interface_id=,
            :save, :server=,
            :server, :server_id, :server_id=,
        :to => :adaptee

        def self.shared?()              true;                               end
        def self.multiple?()            false;                              end
        def self.resource_type()        :elastic_ip;                        end
        def self.expected_ids(computer) [ computer.server.openstack.elastic_ip ]; end

        def public_ip()                adaptee.ip ;                 end
        def name()                      adaptee.ip ;                 end

        #
        # Discovery
        #

        def self.load!(cluster=nil)
          OpenStack.connection.addresses.each do |eip|
            register eip

            # The rest of this definition shows relevant information when -VV
            #   is passed to knife and aids in troubleshooting any refusal to
            #   attach Elastic IPs
            Chef::Log.debug( "OpenStack Pool: #{eip.pool}" )
            if eip.ip.nil?
              Chef::Log.debug( "no Elastic IPs currently allocated" )
            else
              Chef::Log.debug( "available ip match: #{eip.ip}" )
              Chef::Log.debug( "available allocation_id match: #{eip.id}" )
            end
            Chef::Log.debug( "----------------------" )
          end

          cluster.servers.each do |s|
            next if s.openstack.elastic_ip.nil?
            if recall? s.openstack.elastic_ip
              Chef::Log.debug( "Cluster elastic_ip matches #{s.openstack.elastic_ip}" )
            else
              Chef::Log.debug( "No matching Elastic IP for #{s.openstack.elastic_ip}" )
            end
          end

        end

        #
        # Manipulation
        #

        def self.save!(computer)
          return unless computer.created?
          return unless elastic_ip = computer.server.openstack.elastic_ip
          return unless recall? elastic_ip
          # also, in the case of VPC Elastic IPs, can discover and use allocation_id to attach a VPC Elastic IP.
          return unless computer.server.openstack.methods.include?(:elastic_ip)
          if ( computer.server.openstack.elastic_ip.nil?)
            if computer.server.addresses.nil?
              OpenStack.connection.allocate_address
              load!
              elastic_ip = computer.server.addresses.first.public_ip
              Chef::Log.debug( "allocating new Elastic IP address" )
            else
              # Second, :elastic_ip is set, has an address available to use but has no set value available in facet definition.
              elastic_ip = computer.server.addresses.first.public_ip
              Chef::Log.debug( "using first available Elastic IP address" )
            end
          elsif ( !computer.server.openstack.elastic_ip.nil? or cloud.vpc.nil? )
            # Third,  :elastic_ip is set, has an address available to use, has a set value in facet definition and is not VPC.
            elastic_ip = computer.server.openstack.elastic_ip
            Chef::Log.debug( "using requested Elastic IP address" )
          elsif ( computer.server.opentsack.elastic_ip.nil? )
            # Fourth, is exactly like Third but on a VPC domain. (this is functionaility for attaching VPC Elastic IPS)
            allocation_id = computer.server.openstack.allocation_id
            Chef::Log.debug( "using Elastic IP address matched to given Allocation ID" )
          else
            ui.fatal("You have set both :elastic_ip and :auto_elastic_ip in your facet definition; which are mutually exclusive.")
          end
          Ironfan.step(computer.name, "associating Elastic IP #{elastic_ip}", :blue)
          Ironfan.unless_dry_run do
            Ironfan.safely do
              allocation_id = recall(elastic_ip).id
              OpenSTack.connection.associate_address( computer.machine.id, elastic_ip, nil, allocation_id )
            end
          end
        end
      end
    end
  end
end
