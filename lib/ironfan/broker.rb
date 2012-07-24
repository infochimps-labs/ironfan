# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers, to control instance life-cycle and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan

  class Broker < Builder
    field :chef,              Ironfan::Provider::ChefServer,
          :default =>         Ironfan::Provider::ChefServer.new
    collection :providers,    Ironfan::IaasProvider

    def all_providers() [chef, providers.values].flatten; end

    def create!(machines)
      section("Launching machines", :green)
      ui.info("")
      display machines
      create_dependencies! machines
      create_instances! machines
      save! machines
    end

    # TODO: Parallelize
    def create_dependencies!(machines)
      delegate_to all_providers, :create_dependencies! => machines
    end
    # Do serially ensure node is created before instance
    def create_instances!(machines)
      chef.create_instances! machines
      providers.each {|p| p.create_instances! machines}
    end

    #
    #   DISCOVERY
    #

    # Take in a Dsl::Cluster, return Machines populated with
    #   all discovered resources that correlate, plus bogus machines
    #   corresponding to 
    def discover!(cluster)
      # Get fully resolved servers
      servers = cluster.resolve.servers

      servers.each {|server|  }

      machines = Machines.new
      servers.each do |server|
        # ensure that the chosen provider is available
        provider(server.selected_cloud.name)

        # set up a bare machine
#         machine().server = server
        m = Machine.new
        m.server = server
        machines << m
      end

      delegate_to all_providers, :load! => machines
      delegate_to all_providers, :correlate! => machines
      delegate_to all_providers, :validate! => machines
      machines
    end

    #
    #   SYNC
    #

    # TODO: Parallelize
    def save!(machines)
      delegate_to all_providers, :save! => machines
    end

#     def sync_to_chef(machines)
#       providers.each {|p| p.pre_sync!(machines)}
#       chef.sync!(machines)
#     end
# 
#     def sync_to_providers(machines)
# #       sync_keypairs
# #       sync_security_groups
# #       delegate_to_servers( :sync_to_cloud )
#       providers.each {|p| p.sync!(machines)}
#       raise 'incomplete?'
#     end
  end

end