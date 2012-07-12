# require 'ironfan/provider/chef'

# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers to survey the existing instances and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan
  module Broker

    class Machine
      include Gorillib::Builder
      field :chef_node,         Ironfan::Provider::ChefServer::Node
      field :expectation,       Ironfan::Dsl::Server
      field :instance,          Ironfan::Provider::Instance
      field :bogosity,          Symbol

      def key_method()  :object_id;     end
    end

    class Conductor
      include Gorillib::Builder
      field :expectations,      Ironfan::Dsl::Cluster

      field :chef,              Ironfan::Provider::ChefServer::Connection,
            :default =>         Ironfan::Provider::ChefServer::Connection.new
      collection :providers,    Ironfan::Provider::Connection

      collection :machines,     Machine

      def discover!(cluster_dsl)
        set_expectations!(cluster_dsl)
        discover_resources!
        correlate_machines!
      end

      def set_expectations!(cluster)
        cluster.expand_servers  # vivify each facet's Server instances
        self.expectations = cluster.resolve
      end

      def discover_resources!
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

      # Correlate expectations with Chef resources, and IaaS machines 
      #   and related Provider resources. Create "nonexistent" machines
      #   for each un-satisfied server expectation.
      def correlate_machines!
        correlate_expectations!
        correlate_nodes!
        correlate_instances!
      end

      # for all expectations, set up a bare machine
      def correlate_expectations!
        expectations.servers.each do |server|
          m = Machine.new
          m.expectation = server
          machines << m
        end
      end

      # for all chef nodes that match the cluster,
      #   find a machine that matches and attach,
      #   or make a new machine and mark it :unexpected_node
      def correlate_nodes!
        chef.nodes.each do |chef_node|
          match = machines.values.select {|m| chef_node.matches? m }.first
          if match.nil?
            match = Machine.new
            match.bogosity = :unexpected_node
            machines << match
          end
          match.chef_node = chef_node
        end
      end

      # for each provider instances that matches the cluster,
      #   find a machine that matches
      #     attach instance to machine if there isn't one,
      #     or make another and mark both :duplicate_instance
      #   or make a new machine and mark it :unexpected_instance
      def correlate_instances!
        each_instance_of(expectations) do |instance|
          match = machines.values.select {|m| instance.matches? m }.first
          if match.nil?
            match = Machine.new
            match.bogosity = :unexpected_instance
            machines << match
          end
          unless match.instance.nil?
            match.bogosity = :duplicate_instance
            copy = match.dup
            matches << copy
          end
          match.instance = instance
        end
      end
      def each_instance_of(expect,&block)
        all_instances_of(expect).each {|i| yield i }
      end
      def all_instances_of(expect)
        providers.values.map {|p| p.instances_of(expect) }.flatten
      end

      # def slice facet_name=nil, slice_indexes=nil
      #   return Ironfan::ServerSlice.new(self, self.servers) if facet_name.nil?
      #   find_facet(facet_name).slice(slice_indexes)
      # end
      def slice facet_name=nil, slice_indexes=nil
        return machines.values if facet_name.nil?
        owner_name = "#{expectations.full_name}-#{facet_name}"
        facet = machines.values.select {|m| m.expectation.owner_name == owner_name }
        return facet if slice_indexes.nil?
        facet.select {|m| slice_indexes.include? m.expectation.name.to_s }
        # TODO: Fix this to include bogus machines
      end
    end

  end
end