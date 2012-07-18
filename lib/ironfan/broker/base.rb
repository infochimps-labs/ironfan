# require 'ironfan/provider/chef'

# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers, to control instance life-cycle and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan
  module Broker

    class Machine
      include Gorillib::Builder
      field :instance,          Ironfan::Provider::Instance
      field :server,            Ironfan::Dsl::Server
      field :node,              Ironfan::Provider::ChefServer::Node

      field :bogosity,          Symbol

      def name()
        return server.fullname  if server?
        return node.name        if node?
        return instance.name    if instance?
        "unnamed:#{object_id}"
      end

      def display_values(style,values={})
        available_styles = [:minimal,:default,:expanded]
        raise "Bad display style #{style}" unless available_styles.include? style

        values["Name"] =        name
        # We expect these to be over-ridden by the contained classes
        values["Chef?"] =       "no"
        values["State"] =       "not running"

        [ server, node, instance ].each do |source|
          values = source.display_values(style, values) unless source.nil?
        end
        if style == :expanded
          values["Startable"]  = display_boolean(stopped?)
          values["Launchable"] = display_boolean(launchable?)
        end
        values["Bogus"] =       bogosity
        # Only show values that actually have something to show
        values.select {|k,v| !v.to_s.empty?}
      end
      def display_boolean(value)        value ? "yes" : "no";   end

      def server?()     !server.nil?;                   end
      def node?()       !node.nil?;                     end
      def instance?()   !instance.nil?;                 end
      def bogus?()      !bogosity.nil?;                 end

      def created?()    instance? && instance.created?; end
      def launchable?() not created?;                   end
      def stopped?()    created? && instance.stopped?;  end

      def killable?
        return false if permanent?
        node? || created?
      end

      def permanent?
        return false unless server?
        return false unless server.selected_cloud.respond_to? :permanent
        [true, :true, 'true'].include? server.selected_cloud.permanent
      end

      def destroy_instance()    instance.destroy && instance = nil;     end
      def destroy_node()        node.destroy && node = nil;             end
    end

    class Conductor
      include Gorillib::Builder
      field :ui,                Whatever,       :default => ->{Ironfan.ui}

      field :cluster,           Ironfan::Dsl::Cluster

      field :chef,              Ironfan::Provider::ChefServer::Connection,
            :default =>         Ironfan::Provider::ChefServer::Connection.new
      collection :providers,    Ironfan::Provider::Connection

      collection :machines,     Machine

      def initialize(*args,&block)
        super(*args,&block)
#         @machines =             MachineCollection.new
      end

      def discover!
        discover_resources!
        correlate_machines!
      end

      def receive_cluster(cluster)
        cluster.expand_servers          # vivify each facet's Servers
        super(cluster.resolve)          # resolve the cluster attributes before saving
      end

      def discover_resources!
        # Get all relevant chef resources for the cluster.
        chef.discover! cluster

        # Ensure all providers referenced by the DSL are available, and have
        #   them each survey their applicable resources.
        cluster.servers.each {|server| provider(server.selected_cloud.name) }
        providers.each {|p| p.discover! cluster }
      end

      # Correlate servers with Chef resources, and IaaS machines 
      #   and related Provider resources. Create "nonexistent" machines
      #   for each un-satisfied server expectation.
      def correlate_machines!
        expected_machines!
        correlate_nodes!
        correlate_instances!
      end

      # for all server, set up a bare machine
      def expected_machines!
        cluster.servers.each do |server|
          m = Machine.new
          m.server = server
          machines << m
        end
        machines
      end

      # for all chef nodes that match the cluster,
      #   find a machine that matches and attach,
      #   or make a new machine and mark it :unexpected_node
      def correlate_nodes!
        chef.nodes.each do |node|
          match = machines.values.select {|m| node.matches? m }.first
          if match.nil?
            match = Machine.new
            match.bogosity = :unexpected_node
            machines << match
          end
          match.node = node
        end
      end

      # for each provider instance that matches the cluster,
      #   find a machine that matches
      #     attach instance to machine if there isn't one,
      #     or make another and mark both :duplicate_instance
      #   or make a new machine and mark it :unexpected_instance
      def correlate_instances!
        each_instance_of(cluster) do |instance|
          match = machines.values.select {|m| instance.matches? m }.first
          if match.nil?
            match = Machine.new
            match.bogosity = :unexpected_instance
            machines << match
          end
          if match.instance?
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

      # Find all selected machines, as well as any bogus machines from discovery,
      #   and return a new Broker that only handles those machines
      def slice(facet_name=nil, slice_indexes=nil)
        return self if facet_name.nil?
        result =        self.class.new
        f_fullname =    cluster.facet(facet_name).fullname
        slice_array =   build_slice_array(slice_indexes)
        machines.each do |m|
          result.machines << m if (m.bogus? or (        # bogus machine or
            ( m.server.owner_name == f_fullname ) and   # facet match and
              ( slice_array.include? m.server.index or  #   index match or
                slice_indexes.nil? ) ) )                #   no indexes specified
        end
        result
      end
      def build_slice_array(slice_indexes)
        return [] if slice_indexes.nil?
        raise "Bad slice_indexes: #{slice_indexes}" if slice_indexes =~ /[^0-9\.,]/
        eval("[#{slice_indexes}]").map {|idx| idx.class == Range ? idx.to_a : idx}.flatten
      end

      def select_machines(&block)
        result =        self.class.new
        machines.each {|m| result.machines << m if yield m }
        result
      end

      def display(style,&block)
        defined_data = machines.values.map {|m| m.display_values(style) }
        if defined_data.empty?
          ui.info "Nothing to report"
        else
          headings = defined_data.map{|r| r.keys}.flatten.uniq
          Formatador.display_compact_table(defined_data, headings.to_a)
        end
      end
      def joined_names
        machines.map(&:name).join(", ").gsub(/, ([^,]*)$/, ' and \1')
      end

    end
  end
end