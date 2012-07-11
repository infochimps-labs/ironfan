# This class is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers to survey the existing machines and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan
  module Provider

    class Connection
      include Gorillib::Builder

      def self.receive(obj,&block)
        the_module = case obj[:name]
          when :chef;           Chef
          when :ec2;            Ec2
          when :virtualbox;     VirtualBox
          else;                 raise "Unsupported provider #{obj[:name]}"
          end
        the_module::Connection.new(obj,&block)
      end

      def discover!
        raise NotImplementedError, "discover! not implemented for #{self.class}"
      end
    end

    class Machine
      include Gorillib::Builder
      field :expectation,       Ironfan::Dsl::Server
#       field :provider,          Ironfan::Provider::Connection
    end
    
    class IaasConnection < Connection
      collection :machines,     Ironfan::Provider::Machine
      def discover_machines!
        pp "Would discover resources for #{self.class} here, but chickening out instead"
#         raise NotImplementedError, "discover_machines! not implemented for #{self.class}"
      end

    end

  end

  class ProviderBroker
    include Gorillib::Builder
    field :expectations,        Ironfan::Dsl::Cluster
    field :chef,                Ironfan::ChefServer::Connection,
          :default =>           Ironfan::ChefServer::Connection.new
    collection :providers,      Ironfan::Provider::Connection
    collection :machines,       Ironfan::Provider::Machine
    
    def initialize(*args,&block)
      super(*args,&block)
      machines = Gorillib::ModelCollection.new(:object_id,Ironfan::Provider::Machine)
    end

    def discover!(cluster_dsl)
      set_expectations!(cluster_dsl)
      discover_provider_resources!
      discover_machine_states!
    end
    
    def set_expectations!(cluster)
      cluster.expand_servers  # vivify each facet's Server instances
      self.expectations = cluster.resolve
    end

    def discover_provider_resources!
      # Get all relevant chef resources for the cluster
      chef.discover! expectations

      # Ensure all providers referenced by the DSL are available
      expectations.servers.each {|server| provider_for(server) }

      # Find all provider resources for the cluster
      providers.each {|p| p.discover! expectations }
    end

    def provider_for(server)
      provider(server.selected_cloud.name)
    end
    def new_machine(server)
      provider_for(server).new_machine(server)
    end

    # Correlate expectations with Chef resources, and IaaS machines 
    #   and related Provider resources. Create "nonexistent" machines
    #   for each un-satisfied server expectation.
    def discover_machine_states!
      expectations.servers.each do |server|
        node      = chef.find_node(server)
        instances = providers.values.map {|p| p.find_machines(server) }.flatten
        # count = instances.length
        # instances.each {|i| i.bogus = :duplicate }    if count > 1
        # instances << new_machine(server)              if count == 0
        # instances.each do |i|
        #   i.expectation       = server
        #   i.chef_node         = node
        # end
        # machines.receive! instances
      end
      raise NotImplementedError, 'ProviderBroker.discover_machine_states! not fully written yet'
    end
  end
end