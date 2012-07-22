# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers, to control instance life-cycle and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan

  class Broker < Builder
    field :chef,              Ironfan::Provider::ChefServer,
          :default =>         Ironfan::Provider::ChefServer.new
    collection :providers,    Ironfan::IaasProvider

    # Take in a Dsl::Cluster, return Machines populated with
    #   all discovered resources that correlate
    def discover!(cluster)
      cluster.expand_servers
      resolved = cluster.resolve

      discover_resources! resolved
      machines = correlate_machines resolved
      validate(machines)
    end

    def discover_resources!(cluster)
      # Get all relevant chef resources for the cluster.
      chef.discover! cluster

      # Ensure all providers referenced by the DSL are available, and have
      #   them each survey their applicable resources.
      cluster.servers.each {|server| provider(server.selected_cloud.name) }
      providers.each {|p| p.discover! cluster }
    end

    # Correlate servers with Chef and IaaS resources
    def correlate_machines(cluster)
      machines = expected_machines(cluster)
      chef.correlate!(cluster,machines)
      providers.each{|p| p.correlate!(cluster,machines)}
      machines
    end

    # Compare the results
    def validate(machines)
      chef.validate! machines
      providers.each{|p| p.validate!(machines)}
      machines
    end

    # for all servers, set up a bare machine
    def expected_machines(cluster)
      machines = Machines.new
      cluster.servers.each do |server|
        m = Machine.new
        m.server = server
        machines << m
      end
      machines
    end

    def sync_to_chef(machines)
#       sync_roles
#       delegate_to_servers( :sync_to_chef )
      chef.sync!(machines)
    end
    def sync_to_providers(machines)
#       sync_keypairs
#       sync_security_groups
#       delegate_to_servers( :sync_to_cloud )
      providers.each {|p| p.sync!(machines)}
    end
  end

end