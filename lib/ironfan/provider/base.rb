# Providers present a lightweight wrapper for various third-party services,
#   such as Chef's node and client APIs, and Amazon's EC2 APIs. This allows
#   Ironfan ask specialized questions (such as whether a given resource 
#   matches
module Ironfan

  class Provider < Builder
    field :types,       Array
    # Discovery
    field :discover,    Array,  :default =>->{types}
    field :correlate,   Array,  :default =>->{discover}
    field :validate,    Array,  :default =>->{correlate}
    # Synchronization
    field :sync,        Array,  :default =>->{types}

    def self.receive(obj,&block)
      obj[:_type] = case obj[:name]
        when    :chef;          Chef
        when    :ec2;           Ec2
        when    :virtualbox;    VirtualBox
        else;   raise "Unsupported provider #{obj[:name]}"
      end unless native?(obj)
      super
    end

    def delegate_to_resources(types,call,*args)
      types.each do |type|
        self.send(type).instance_eval do |i|
          i.send(call,*args) if i.respond_to? call
        end
      end
    end

    [:discover,:correlate,:validate].each do |action|
      method = "#{action.to_s}!".to_sym
      define_method method do |*args|
        collections = read_attribute(action)
        delegate_to_resources(collections,method,*args)
      end
    end

    def sync!(broker)
      raise NotImplementedError, "sync!(broker) not implemented for #{self.class}"
    end

    class Resource < Builder
      field             :adaptee,       Whatever
      field             :users,         Array,          :default => []
      field             :bogus,         Array,          :default => []
      field             :owner,         Whatever

      def bogus?()      !bogus.empty?;                  end

    end

    class ResourceCollection < Gorillib::ModelCollection
      self.key_method = :name

      # Find all resources of this type that match this cluster
      def discover!(cluster)
        raise NotImplementedError, "discover! not implemented for #{self.class}"
      end

      # Connect discovered resources to the machines, adding fake machines to
      #   hold extraneous resources (if warranted)
      def correlate!(cluster,machines)
        raise NotImplementedError, "correlate! not implemented for #{self.class}"
      end

      # Optional final review of machines and resources, to ensure correlation
      #   between important parts (like Chef::Client and Chef::Node)
      #def validate!(machines); end
    end
  end

  class IaasProvider < Provider
    collection          :instances,     Instance

    def discover_instances!
      raise NotImplementedError, "discover_instances! not implemented for #{self.class}"
    end

    class Instance < Resource
      def remove!
        raise NotImplementedError, "remove! not implemented for #{self.class}"
      end
    end
  end

end