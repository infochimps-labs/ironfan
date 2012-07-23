# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers, to control instance life-cycle and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan
  class Broker

    class Machine < Builder
      collection :resources,    Ironfan::Provider::Resource
      field :server,            Ironfan::Dsl::Server
      delegate :[],:[]=,:include?,
          :to =>                :resources

      # Only used for bogus servers
      field :name,              String
      field :bogus,             Array,          :default => []

      def name()
        return server.fullname  if server?
        return @name            if @name
        "unnamed:#{object_id}"
      end

      def display_values(style,values={})
        available_styles = [:minimal,:default,:expanded]
        raise "Bad display style #{style}" unless available_styles.include? style

        values["Name"] =        name
        # We expect these to be over-ridden by the contained classes
        values["Chef?"] =       "no"
        values["State"] =       "not running"

        values = server.display_values(style, values) unless server.nil?
        [ :node, :instance ].each do |source|
          values = self[source].display_values(style, values) if include? source
        end
        if style == :expanded
          values["Startable"]  = display_boolean(stopped?)
          values["Launchable"] = display_boolean(launchable?)
        end
        values["Bogus"] =       bogus.join(',')
        # Only show values that actually have something to show
        values.select {|k,v| !v.to_s.empty?}
      end
      def display_boolean(value)        value ? "yes" : "no";   end

      #
      # Actions
      #
      def remove_instance!
        resources.delete(:instance).remove!
      end
      def remove_node!
        resources.delete(:client).remove! if client?
        resources.delete(:node).remove! if node?
      end

      #
      # Accessors
      #
      def client
        self[:client]
      end
      def instance
        self[:instance]
      end
      def node
        self[:node]
      end
      #
      # Status flags
      #
      def bogus?
        not bogus.empty?
      end
      def client?
        not client.nil?
      end
      def created?()
        instance? and self[:instance].created?
      end
      def instance?()
        not instance.nil?
      end
      def killable?
        not permanent? and (node? or created?)
      end
      def launchable?()
        not bogus? and not created?
      end
      def node?()
        not node.nil?
      end
      def permanent?
        return false unless server?
        return false unless server.selected_cloud.respond_to? :permanent
        [true, :true, 'true'].include? server.selected_cloud.permanent
      end
      def server?
        not server.nil?
      end
      def stopped?()
        created? and self[:instance].stopped?
      end

    end

    class Machines < Gorillib::ModelCollection
      self.item_type    = Machine
      self.key_method   = :object_id
      delegate :first, :map,
          :to           => :values

      # Return the selection inside another Machines
      def select(&block)
        result          = self.class.new
        values.select(&block).each{|m| result << m}
        result
      end

      # Find all selected machines, as well as any bogus machines from discovery
      def slice(facet_name=nil, slice_indexes=nil)
        return self if (facet_name.nil? and slice_indexes.nil?)
        result          = self.class.new
        slice_array     = build_slice_array(slice_indexes)
        each do |m|
          result << m if (m.bogus? or (                 # bogus machine or
            ( m.server.facet_name == facet_name ) and   # facet match and
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

      def display(ui, style,&block)
        defined_data = map {|m| m.display_values(style) }
        if defined_data.empty?
          ui.info "Nothing to report"
        else
          headings = defined_data.map{|r| r.keys}.flatten.uniq
          Formatador.display_compact_table(defined_data, headings.to_a)
        end
      end
      def joined_names
        values.map(&:name).join(", ").gsub(/, ([^,]*)$/, ' and \1')
      end
    end

  end
end