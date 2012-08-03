# Providers present a lightweight wrapper for various third-party services,
#   such as Chef's node and client APIs, and Amazon's EC2 APIs. This allows
#   Ironfan ask specialized questions (such as whether a given resource 
#   matches
module Ironfan
  class Provider < Builder

    def self.receive(obj,&block)
      obj[:_type] = case obj[:name]
        when    :chef;          Chef
        when    :ec2;           Ec2
        when    :virtualbox;    VirtualBox
        else;   raise "Unsupported provider #{obj[:name]}"
      end unless native?(obj)
      super
    end

    def resources
      raise "missing #{self.class}.resources declaration"
    end

    def conterminous_with_machine
      Chef::Log.debug "no resources elected to die with Machines in #{self.class}"
      []
    end

    #
    # Discovery
    #
    def load!(computers)
      delegate_to(resources) { load! computers }
    end

    def correlate!(computers)
      computers.each do |computer|
        delegate_to(resources) { correlate! computer }
      end
    end

    def validate!(computers)
      computers.each do |computer|
        delegate_to(resources) { validate_computer! computer }
      end
      delegate_to(resources) { validate_resources! computers }
    end

    #
    # Manipulation
    #
    def ensure_prerequisites!(computers)
      computers.each do |computer|
        delegate_to(resources) { create! computer }
      end
    end

    def destroy_machines!(computers)
      computers.each do |computer|
        delegate_to(conterminous_with_machine) { destroy! computer }
      end
    end

    def save!(computers)
      computers.each do |computer|
        delegate_to(resources) { save! computer }
      end
    end

    class Resource < Builder
      @@known = {}
      field             :adaptee,       Whatever
      field             :bogus,         Array,          :default => []
      attr_accessor     :owner

      def bogus?()      !bogus.empty?;                  end

      #
      # Discovery
      #
      def self.load!(*p)                Ironfan.noop(self,__method__,*p);   end
      def self.correlate!(*p)           Ironfan.noop(self,__method__,*p);   end
      def self.validate_computer!(*p)   Ironfan.noop(self,__method__,*p);   end
      def self.validate_resources!(*p)  Ironfan.noop(self,__method__,*p);   end

      #
      # Manipulation
      #
      def self.create!(*p)              Ironfan.noop(self,__method__,*p);   end
      def self.save!(*p)                Ironfan.noop(self,__method__,*p);   end
      def self.destroy!(*p)             Ironfan.noop(self,__method__,*p);   end

      #
      # Utilities
      #
      def self.remember(resource,options={})
        index = options[:id] || resource.name
        index += options[:append_id] if options[:append_id]
        self.known[index] = resource
      end

      # Register and return the (adapted) object with the collection
      def self.register(native)
        result = new(:adaptee => native)
        remember result unless result.nil?
      end

      def self.recall?(id)
        self.known.include? id
      end

      def self.recall(id=nil)
        return self.known if id.nil?
        self.known[id]
      end

      def self.forget(id)
        self.known.delete(id)
      end

      # Provide a separate namespace in @@known for each subclass
      def self.known
        @@known[self.name] ||= {}
      end
    end

  end

  class IaasProvider < Provider
    def machine_class
      self.class.const_get(:Machine)
    end

    #
    # Manipulation
    #
    def ensure_prerequisites!(computers)
      # Create all things that aren't machines
      targets = resources.reject {|type| type < IaasProvider::Machine}
      computers.each do |computer|
        delegate_to(targets) { create! computer }
      end
    end

    def create_machines!(computers)
      computers.each do |computer|
        delegate_to(machine_class) { create! computer }
      end
    end

    def destroy_machines!(computers)
      targets = conterminous_with_machine + [ machine_class ]
      computers.each do |computer|
        delegate_to(targets) { destroy! computer }
      end
    end

    def save!(computers)
      computers.each do |computer|
        delegate_to(resources) { save! computer }
      end
    end

    #
    # Machine Manipulation
    #
    def start_machines!(computers)
      computers.each do |computer|
        delegate_to(machine_class) { start! computer }
      end
    end

    def stop_machines!(computers)
      computers.each do |computer|
        delegate_to(machine_class) { stop! computer }
      end
    end

    class Machine < Resource
    end
  end

end