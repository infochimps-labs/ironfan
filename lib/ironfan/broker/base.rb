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
      all_providers.each do {|p| p.create_dependencies! machines}
    end
    # Do serially ensure node is created before instance
    def create_instances!(machines)
      chef.create_instances! machines
      providers.each do {|p| p.create_instances! machines}
    end

    #
    #   DISCOVERY
    #

    # Take in a Dsl::Cluster, return Machines populated with
    #   all discovered resources that correlate, plus bogus machines
    #   corresponding to 
    def discover!(cluster)
      # Ensure all providers referenced by the DSL are available, and have
      #   them each survey their applicable resources.
      cluster.each {|server| provider(server.selected_cloud.name) }

      # for all servers, set up a bare machine
      machines = Machines.new
      cluster.resolve.servers.each do |server| # Get fully resolved servers
        m = Machine.new
        m.server = server
        machines << m
      end

      all_providers.each do {|p| p.load! machines }
      all_providers.each do {|p| p.correlate! machines }
      all_providers.each do {|p| p.validate! machines }
      machines
    end

    #
    #   SYNC
    #

    # TODO: Parallelize
    def save!(machines)
      all_providers.each do {|p| p.save! machines }
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