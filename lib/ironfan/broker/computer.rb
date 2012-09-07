module Ironfan
  class Broker

    class Computer < Builder
      collection :resources,    Whatever
      collection :drives,       Ironfan::Broker::Drive
      collection :providers,    Ironfan::Provider
      field :server,            Ironfan::Dsl::Server
      delegate :[],:[]=,:include?,:delete,
          :to =>                :resources

      # Only used for bogus servers
      field :name,              String
      field :bogus,             Array,          :default => []

      def initialize(*args)
        super
        providers[:chef] ||=    Ironfan::Provider::ChefServer
        return unless server
        providers[:iaas] =      server.selected_cloud.provider
        volumes =               server.volumes.values
        volumes +=              server.implied_volumes
        volumes.each { |v| self.drive v.name, :volume => v }
      end

      def name
        return server.fullname  if server?
        return @name            if @name
        "unnamed:#{object_id}"
      end

      #
      # Discovery
      #
      def correlate
        chosen_resources.each do |res|
          unless res.respond_to? :expected_ids
            Chef::Log.warn("FIXME: Using correlate! instead of on_correlate in #{res}")
            res.correlate! self
            return
          end
        
          res.expected_ids(self).each do |id|
            next unless res.recall? id

            recalled =            res.recall id
            recalled.users <<     self

            target =              res.resource_type.to_s
            target +=             "__#{id}" if res.multiple?
            self[target.to_sym] = recalled

            recalled.on_correlate(self)
          end
        end
      end

      def correlate_with(res)
      end

      def validate
        computer = self
        Ironfan.delegate_to(chosen_resources) { validate_computer! computer }
      end

      #
      # Manipulation
      #
      def kill(options={})
        target_resources = chosen_resources(options)
        resources.each do |res|
          next unless target_resources.include? res.class
          res.destroy unless res.shared?
        end
      end

      def launch
        ensure_dependencies
        providers[:iaas].machine_class.create! self
        save
      end

      def stop
        machine.stop
        node.announce_state :stopped
      end

      def start
        ensure_dependencies
        machine.start
        node.announce_state :started
        save
      end

      def save(options={})
        chosen_resources(options).each {|res| res.save! self}
      end

      #
      # Utility
      #
      def chosen_providers(options={})
        case options[:providers]
        when :all,nil   then    [:chef,:iaas]
        else                    [ (options[:providers]) ]
        end
      end

      def chosen_resources(options={})
        chosen_providers(options).map do |name|
          providers[name].resources
        end.flatten
      end

      def ensure_dependencies
        chosen_resources.each do |res|
#           ensure_resource res unless res < Ironfan::IaasProvider::Machine
          res.create! self unless res < Ironfan::IaasProvider::Machine
        end
      end

#       def ensure_resource(type)
#         if type.multiple?
#           existing = resources[type.resource_id]
#         else
#           
#         end
#       end

      #
      # Display
      #
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
      # Discovery
      #
      def correlate
        Ironfan.delegate_to(values)     { correlate }
      end

      def validate
        providers = values.map {|c| c.providers.values}.flatten
        computers = self

        Ironfan.delegate_to(values)     { validate }
        Ironfan.delegate_to(providers)  { validate computers }
      end

      #
      # Manipulation
      #
      def kill(options={})
        Ironfan.parallelize(values) { kill(options) }
      end
      def launch
        Ironfan.parallelize(values) { launch }
      end
      def save(options={})
        Ironfan.parallelize(values) { save(options) }
      end
      def start
        Ironfan.parallelize(values) { start }
      end
      def stop
        Ironfan.parallelize(values) { stop }
      end

      #
      # Utility
      #

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

      # provide a human-readable list of names
      def joined_names
        values.map(&:name).join(", ").gsub(/, ([^,]*)$/, ' and \1')
      end
    end

  end
end