module Ironfan
  class Broker

    class Computer < Builder
      collection :resources,    Ironfan::Provider::Resource
      collection :drives,       Ironfan::Broker::Drive
      field :server,            Ironfan::Dsl::Server
      delegate :[],:[]=,:include?,:delete,
          :to =>                :resources

      # Only used for bogus servers
      field :name,              String
      field :bogus,             Array,          :default => []

      def initialize(*args)
        super
        return unless server
        volumes =       server.volumes.values
        if server.selected_cloud.respond_to? :implied_volumes
          volumes +=    server.selected_cloud.implied_volumes
        end
        volumes.each {|v| self.drive(v.name).volume = v}
      end

      def name
        return server.fullname  if server?
        return @name            if @name
        "unnamed:#{object_id}"
      end

      # #
      # # Discovery
      # #
      # correlate
      # validate

      # #
      # # Manipulation
      # # 
      # destroy
      # create
      def stop
        machine.stop
        node.announce_state :stopped
      end

      def start
        #ensure_machine_dependencies
        machine.start
        node.announce_state :started
      end
      # start
      # save

      # #
      # # Display
      # # 
      # to_display

      def to_display(style,values={})
        unless [:minimal,:default,:expanded].include? style
          raise "Bad display style #{style}"
        end

        values["Name"] =        name
        # We expect these to be over-ridden by the contained classes
        values["Chef?"] =       "no"
        values["State"] =       "not running"

        delegate_to([ server, node, machine ].compact) do
          to_display style, values
        end

        if style == :expanded
          values["Startable"]  = display_boolean(stopped?)
          values["Launchable"] = display_boolean(launchable?)
        end
        values["Bogus"] =       bogus.join(',')

        # Only show values that actually have something to show
        values.delete_if {|k,v| v.to_s.empty?}
        values
      end
      def display_boolean(value)        value ? "yes" : "no";   end

      #
      # Accessors
      #
      def bogus
        resources.values.map(&:bogus).flatten
      end
      def client
        self[:client]
      end
      def machine
        self[:machine]
      end
      def machine=(value)
        self[:machine] = value
      end
      def node
        self[:node]
      end
      def node=(value)
        self[:node]= value
      end

      #
      # Status flags
      #
      def bogus?
        resources.values.any?(&:bogus?)
      end
      def client?
        not client.nil?
      end
      def created?
        machine? and machine.created?
      end
      def machine?
        not machine.nil?
      end
      def killable?
        not permanent? and (node? or created?)
      end
      def launchable?
        not bogus? and not created?
      end
      def node?
        not node.nil?
      end
      def permanent?
        return false unless server?
        return false unless server.selected_cloud.respond_to? :permanent
        [true, :true, 'true'].include? server.selected_cloud.permanent
      end
      def running?
        machine? and machine.running?
      end
      def server?
        not server.nil?
      end
      def stopped?
        machine? and machine.stopped?
      end

    end

    class Computers < Gorillib::ModelCollection
      self.item_type    = Computer
      self.key_method   = :object_id
      delegate :first, :map, :any?,
          :to           => :values
      attr_accessor     :cluster

      def initialize(*args)
        super
        options = args.pop or return
        self.cluster = options[:cluster]
        create_expected!
      end

      #
      # Commands
      #
      def start
        values.each {|computer| computer.start }
      end
      def stop
        values.each {|computer| computer.stop }
      end

      # set up new computers for each server in the cluster definition
      def create_expected!
        self.cluster.servers.each do |server|
          self << Computer.new(:server => server)
        end unless self.cluster.nil?
      end

      # Return the selection inside another Computers collection
      def select(&block)
        result = empty_copy
        values.select(&block).each{|m| result << m}
        result
      end

      def empty_copy
        result          = self.class.new
        result.cluster  = self.cluster unless self.cluster.nil?
        result
      end

      # Find all selected computers, as well as any bogus computers from discovery
      def slice(facet_name=nil, slice_indexes=nil)
        return self if (facet_name.nil? and slice_indexes.nil?)
        result          = empty_copy
        slice_array     = build_slice_array(slice_indexes)
        each do |m|
          result << m if (m.bogus? or (                 # bogus computer or
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

      # Utility function to provide a human-readable list of names
      def joined_names
        values.map(&:name).join(", ").gsub(/, ([^,]*)$/, ' and \1')
      end
    end

  end
end