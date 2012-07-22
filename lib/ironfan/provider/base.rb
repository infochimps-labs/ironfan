# Providers present a lightweight wrapper for various third-party services,
#   such as Chef's node and client APIs, and Amazon's EC2 APIs. This allows
#   Ironfan ask specialized questions (such as whether a given resource 
#   matches
module Ironfan

  class Provider < Builder
    field :types,      Array

    def self.receive(obj,&block)
      obj[:_type] = case obj[:name]
        when    :chef;          Chef
        when    :ec2;           Ec2
        when    :virtualbox;    VirtualBox
        else;   raise "Unsupported provider #{obj[:name]}"
      end unless native?(obj)
      super
    end

    def discover!(cluster)
      types.each {|type| self.send(type).discover!(cluster) }
    end

    def correlate!(cluster,machines)
      types.each {|type| self.send(type).correlate!(cluster,machines) }
    end

    def validate!(machines)
      types.each {|type| self.send(type).validate!(machines) }
    end

    def sync!(broker)
      raise NotImplementedError, "sync!(broker) not implemented for #{self.class}"
    end

    class Resource < Builder
      field             :adaptee,       Whatever
#       field             :owner,         Provider
      field             :users,         Array,          :default => []
      field             :bogus,         Array,          :default => []

      def bogus?()      !bogus.empty?;                  end

#       def matches?(machine)
#         raise NotImplementedError, "matches? not implemented for #{self.class}"
#       end
# 
#       def sync!(broker)
#         raise NotImplementedError, "sync!(broker) not implemented for #{self.class}"
#       end
# 
#       def validate!(machines)
#         # Override in subclasses
#       end
    end

    class ResourceCollection < Gorillib::ModelCollection
      self.key_method = :name

      # Find all resources of this type that match this cluster
      def discover!(cluster)
        raise NotImplementedError, "matches? not implemented for #{self.class}"
      end

      # Connect discovered resources to the machines
      def correlate!(cluster,machines)
        raise NotImplementedError, "matches? not implemented for #{self.class}"
      end

      # Review all machines and resources, faking new machines as necessary
      #   to display bogus resources
      def validate!(machines)
        # Override in subclasses
      end
    end
  end

  class IaasProvider < Provider
    collection          :instances,     Instance
    def discover_instances!
      raise NotImplementedError, "discover_instances! not implemented for #{self.class}"
    end

    class Instance < Resource
    end
  end

end