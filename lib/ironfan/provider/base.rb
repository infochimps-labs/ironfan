# Providers present a lightweight wrapper for various third-party services,
#   such as Chef's node and client APIs, and Amazon's EC2 APIs. This allows
#   Ironfan ask specialized questions (such as whether a given resource 
#   matches
module Ironfan
  class Provider

    #
    # Resource
    #
    class Resource
      include Gorillib::Builder
      field    :adaptee,        Whatever

      def matches?(machine)
        raise NotImplementedError, "matches? not implemented for #{self.class}"
      end
      def sync!(broker)
        raise NotImplementedError, "sync!(broker) not implemented for #{self.class}"
      end
    end

    #
    # Provider
    #
    include Gorillib::Builder
    def self.receive(obj,&block)
      klass = case obj[:name]
        when :chef;           Chef
        when :ec2;            Ec2
        when :virtualbox;     VirtualBox
        else;                 raise "Unsupported provider #{obj[:name]}"
        end
      klass.new(obj,&block)
    end

    def discover!
      raise NotImplementedError, "discover! not implemented for #{self.class}"
    end
    def sync!(broker)
      raise NotImplementedError, "sync!(broker) not implemented for #{self.class}"
    end
  end

  class IaasProvider < Provider
    #
    # Instance
    #
    class Instance < Resource
    end
    
    #
    # IaasProvider
    #
    collection :instances,    Instance
    def discover_instances!
      raise NotImplementedError, "discover_instances! not implemented for #{self.class}"
    end
  end

end