module Ironfan
  class Broker

    class Computer < Builder

      field :server,            Ironfan::Dsl::Server
      collection :resources,    Ironfan::Provider::Resource, :key_method => :name
      collection :drives,       Ironfan::Broker::Drive,      :key_method => :name
      collection :providers,    Whatever,                    :key_method => :name
      delegate :[], :[]=, :include?, :delete, :to => :resources

      # Only used for bogus servers
      field :name,              String
      field :bogus,             Array,  :default => []

      def initialize(*args)
        super
        providers[:chef] ||=    Ironfan::Provider::ChefServer
        return unless server
        providers[:iaas]   = server.selected_cloud.provider
        volumes            = server.volumes.values
        volumes           += server.implied_volumes
        volumes.each{|vol| self.drive vol.name, :volume => vol }
      rescue StandardError => err ; err.polish("#{self.class} on '#{args.inspect}'") rescue nil ; raise
      end

      def name
        return server.full_name if server?
        return @name            if @name
        "unnamed:#{object_id}"
      end

      #
      # Discovery
      #
      def correlate
        chosen_resources.each do |res|
          res.expected_ids(self).each do |id|
            next unless res.recall? id

            recalled =  res.recall id
            recalled.users << self

            target  = res.resource_type.to_s
            target += "__#{id}" if res.multiple?
            self[target.to_sym] = recalled

            recalled.on_correlate(self)
          end
        end
      end

      def validate
        computer = self
        chosen_resources.each {|r| r.validate_computer! computer }
      end

      #
      # Manipulation
      #
      def kill(options={})
        target_resources = chosen_resources(options)
        resources.each do |res|
          next unless target_resources.include? res.class
          descriptor = "#{res.class.resource_type} named #{res.name}"
          if res.shared?
            Chef::Log.debug("Not killing shared resource #{descriptor}")
          else
            Ironfan.step(self.name, "Killing #{descriptor}")
            res.destroy
          end
        end
      end

      def launch
        ensure_dependencies
        iaas_provider.machine_class.create! self
        node.announce_state :started
        save
        self
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

      def chef_provider ; providers[:chef] ; end
      def iaas_provider ; providers[:iaas] ; end

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
          # ensure_resource res unless res < Ironfan::IaasProvider::Machine
          res.create! self unless res < Ironfan::IaasProvider::Machine
        end
      end

      def chef_client_script_content
        cloud = server.selected_cloud
        return @chef_client_script_content if @chef_client_script_content
        return unless cloud.chef_client_script
        script_filename = File.expand_path("../../../config/#{cloud.chef_client_script}", File.dirname(File.realdirpath(__FILE__)))
        @chef_client_script_content = Ironfan.safely{ File.read(script_filename) }
      end

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

        [ server, node, machine ].compact.each do |part|
          part.to_display style, values
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
      def node
        self[:node]
      end
      def node=(value)
        self[:node]= value
      end

      def environment ; server && server.environment ; end

      #
      # client
      #
      def client
        self[:client]
      end
      def private_key ; client? ? client.private_key : nil ; end

      #
      # Machine
      #
      def machine
        self[:machine]
      end
      def machine=(value)
        self[:machine] = value
      end
      def dns_name         ; machine? ? machine.dns_name : nil ; end
      def bootstrap_distro ; (server && server.selected_cloud) ? server.selected_cloud.bootstrap_distro : nil ; end

      def keypair
        resources[:keypair]
      end

      def ssh_user         ; (server && server.selected_cloud) ? server.selected_cloud.ssh_user : nil ; end

      def ssh_identity_file
        if    keypair                         then keypair.key_filename
        elsif server && server.selected_cloud then server.selected_cloud.ssh_identity_file(self)
        else nil
        end
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
        machine? && machine.created?
      end
      def machine?
        not machine.nil?
      end
      def killable?
        (not bogus?) && (not permanent?) && (node? || client? || created?)
      end
      def launchable?
        (not bogus?) && (not created?)
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
        machine? && machine.running?
      end
      def server?
        not server.nil?
      end
      def stopped?
        machine? && machine.stopped?
      end

      # @return [Boolean] true if machine is likely to be reachable by ssh
      def sshable?
        # if there's any hope of success, give it a try.
        running? || node?
      end

      def receive_providers(objs)
        objs = objs.map do |obj|
          if obj.is_a?(String) then obj = Gorillib::Inflector.constantize(Gorillib::Inflector.camelize(obj.gsub(/\./, '/'))) ; end
          obj
        end
        super(objs)
      end

      def to_s
        "<#{self.class}(server=#{server}, resources=#{resources && resources.inspect_compact}, providers=#{providers && providers.inspect_compact})>"
      end
    end

    class Computers < Gorillib::ModelCollection
      self.item_type  = Computer
      self.key_method = :object_id
      delegate        :first, :map, :any?, :to => :values
      attr_accessor   :cluster

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
        values.each{|c| c.correlate }
      end

      def validate
        computers = self
        values.each{|c| c.validate }
        values.map {|c| c.providers.values}.flatten.uniq.each {|p| p.validate computers }
      end

      def group_action(verb)
        computers = self
        provider_keys = values.map{|c| c.chosen_providers({ :providers => :iaas })}.flatten.uniq
        providers     = provider_keys.map{|pk| values.map{|c| c.providers[pk] } }.flatten.compact.uniq
        providers.each{|p| p.send(verb, computers) }
      end

      def prepare
        group_action(:prepare!)
      end

      def aggregate
        group_action(:aggregate!)
      end

      #
      # Manipulation
      #
      def kill(options={})
        Ironfan.parallel(values){|cc| cc.kill(options) }
      end
      def launch
        Ironfan.parallel(values){|cc| cc.launch }
      end
      def save(options={})
        Ironfan.parallel(values){|cc| cc.save(options) }
      end
      def start
        Ironfan.parallel(values){|cc| cc.start }
      end
      def stop
        Ironfan.parallel(values){|cc| cc.stop }
      end

      def environments
        map{|comp| comp.environment }.uniq
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
        values.select(&block).each{|mach| result << mach}
        result
      end

      def empty_copy
        result          = self.class.new
        result.cluster  = self.cluster unless self.cluster.nil?
        result
      end

      # Find all selected computers, as well as any bogus computers from discovery
      def slice(facet_name=nil, slice_indexes=nil)
        return self if (facet_name.nil? && slice_indexes.nil?)
        slice_array     = build_slice_array(slice_indexes)
        select do |mach|
          mach.bogus? or (
            # facet match, and index match (or no indexes specified)
            (mach.server.facet_name == facet_name) &&
            (slice_array.include?(mach.server.index) || slice_indexes.nil?))
        end
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

      def to_s
        "#{self.class}[#{values.map(&:name).join(",")}]"
      end
    end

  end
end
