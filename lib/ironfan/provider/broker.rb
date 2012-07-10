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
    end
    
    class Machine
      include Gorillib::Builder

      field :expectation,       Ironfan::Dsl::Server
#       field :provider,          Ironfan::Provider::Connection
    end

  end

  class ProviderBroker
    include Gorillib::Builder

    collection :providers,      Ironfan::Provider::Connection
    collection :machines,       Ironfan::Provider::Machine

    def discover!(cluster)
      # TODO: Turn this into calls against Compute subclasses?
      # resolve all of the individual server definitions
      servers = []
      cluster.facets.each{|f| f.servers.each{|s| servers << s.resolve }}
      
      # for each server, determine target cloud and prepare a provider for it
      servers.each {|s| provider(s.selected_cloud.name) }
      provider(:chef)

      # for each provider, look for machines (& other things?) associated with the cluster
#       machines = []
      providers.each do |p|
        p.discover!(cluster)
      end
      # for each machine associated with the cluster, find corresponding server or mark bogus
      # (for each other thing, find corresponding machine or mark bogus?)
      raise NotImplementedError, 'ProviderBroker.new.discover!(cluster) not written yet'
    end
  end
end