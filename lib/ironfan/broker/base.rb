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
      field :expected,          Ironfan::Dsl::Server
      field :instance,          Ironfan::Provider::Instance
      field :bogosity,          Symbol

      def key_method()          :object_id;     end
      def name()
        return expected.full_name       unless expected.nil?
        return chef_node.name           unless chef_node.nil?
        return instance.name            unless instance.nil?
        "unnamed:#{object_id}"
      end

      def display_values(style,values={})
        available_styles = [:minimal,:default,:expanded]
        raise "Bad display style #{style}" unless available_styles.include? style

        values["Name"] =        name
        values["Chef?"] =       "no"
        values["State"] =       "not running"

        [ expected, chef_node, instance ].each do |source|
          values = source.display_values(style, values) unless source.nil?
        end
        values
      end
    end

    class MachineCollection < Gorillib::ModelCollection
      def initialize(key_meth=nil,obj_factory=nil)
        obj_factory ||= Machine
        super(key_meth, obj_factory)
      end

      def display(style)
        defined_data = @clxn.map {|k,m| m.display_values(style) }
        if defined_data.empty?
          ui.info "Nothing to report"
        else
          headings = defined_data.map{|r| r.keys}.flatten.uniq
          Formatador.display_compact_table(defined_data, headings.to_a)
        end
      end
    end

    class Conductor
      include Gorillib::Builder
      field :expected,          Ironfan::Dsl::Cluster

      field :chef,              Ironfan::Provider::ChefServer::Connection,
            :default =>         Ironfan::Provider::ChefServer::Connection.new
      collection :providers,    Ironfan::Provider::Connection

      collection :machines,     Machine

      def initialize(*args,&block)
        super(*args,&block)
        @machines =             MachineCollection.new
      end

      def discover!
        discover_resources!
        correlate_machines!
      end

      def receive_expected(cluster)
        cluster.expand_servers          # vivify each facet's Server instances
        super(cluster.resolve)          # resolve the cluster attributes before saving
      end

      def discover_resources!
        # Get all relevant chef resources for the cluster.
        chef.discover! expected

        # Ensure all providers referenced by the DSL are available, and have
        #   them each survey their applicable resources.
        expected.servers.each {|server| provider(server.selected_cloud.name) }
        providers.each {|p| p.discover! expected }
      end

      # Correlate expectations with Chef resources, and IaaS machines 
      #   and related Provider resources. Create "nonexistent" machines
      #   for each un-satisfied server expectation.
      def correlate_machines!
        expected_machines!
        correlate_nodes!
        correlate_instances!
      end

      # for all expected, set up a bare machine
      def expected_machines!
        expected.servers.each do |server|
          m = Machine.new
          m.expected = server
          machines << m
        end
        machines
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
        each_instance_of(expected) do |instance|
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

      # Find all selected machines, as well as any bogus machines from discovery
      def slice(facet_name=nil, slice_indexes=nil)
        return machines if facet_name.nil?
        result = MachineCollection.new

        owner_name = "#{expected.full_name}-#{facet_name}"
        facet = machines.values.select do |m| # Always show bogus nodes
          !m.bogosity.nil? or m.expected.owner_name == owner_name
        end
        return result.receive! facet if slice_indexes.nil?

        raise "Bad slice_indexes: #{slice_indexes}" if slice_indexes =~ /[^0-9\.,]/
        slice_array = eval("[#{slice_indexes}]").map do |idx|
          idx.class == Range ? idx.to_a : idx
        end.flatten
        servers = facet.select do |m|
          !m.bogosity.nil? or slice_array.include? m.expected.index
        end
        result.receive! servers
      end
    end

  end
end