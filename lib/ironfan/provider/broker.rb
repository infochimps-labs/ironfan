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
      
      def discover_resources!
        pp "Would discover resources for #{self.class} here, but chickening out instead"
#         raise NotImplementedError, "discover_resources! not implemented for #{self.class}"
      end
    end

    class Machine
      include Gorillib::Builder

#       field :expectation,       Ironfan::Dsl::Server
#       field :provider,          Ironfan::Provider::Connection
    end

  end

  class ProviderBroker
    include Gorillib::Builder
    field :expectations,        Ironfan::Dsl::Cluster
    collection :providers,      Ironfan::Provider::Connection

#     collection :machines,       Ironfan::Provider::Machine
#     def initialize(*args,&block)
#       super(*args,&block)
#       expectations.key_method = :full_name
#     end

    def discover!(cluster_dsl)
      # discover_ironfan!
      discover_expectations!(cluster_dsl)

      ## Can I just push :chef into the provider stack first, and rely on consistent order
      ##   of hashing to do it first?
      # discover_chef_nodes!
      ## Moving this before provider discovery; is this okay?
      # discover_chef_clients!
#       discover_chef_resources!

      # discover_fog_servers!
      discover_provider_resources!

      # discover_volumes!
      #   # Walk the list of servers, asking each to discover its volumes.

      raise NotImplementedError, 'ProviderBroker.discover! not fully written yet'
    end
    
    def discover_expectations!(cluster)
      cluster.expand_servers  # vivify each facet's Ironfan::Dsl::Server instances
      self.expectations = cluster.resolve
    end

    def discover_provider_resources!
      # Ensure all providers referenced by the DSL are all available
      provider(:chef)
      expectations.servers.each {|s| provider(s.selected_cloud.name) }

      providers.each {|p| p.discover! }
    end
    
  end
end