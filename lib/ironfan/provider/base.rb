# Providers present a lightweight wrapper for various third-party services,
#   such as Chef's node and client APIs, and Amazon's EC2 APIs. This allows
#   Ironfan ask specialized questions (such as whether a given resource 
#   matches
module Ironfan
  class Provider
    include Gorillib::Builder
    def self.receive(obj,&block)
      obj[:_type] = case obj[:name]
        when    :chef;          Chef
        when    :ec2;           Ec2
        when    :virtualbox;    VirtualBox
        else;   raise "Unsupported provider #{obj[:name]}"
      end unless native?(obj)
      super
    end

    def discover!
      raise NotImplementedError, "discover! not implemented for #{self.class}"
    end
    def sync!(broker)
      raise NotImplementedError, "sync!(broker) not implemented for #{self.class}"
    end

    class Resource
      include Gorillib::Builder
      field             :adaptee,       Whatever
      field             :owner,         Provider
      collection        :users,         Ironfan::Broker::Machine

      def matches?(machine)
        raise NotImplementedError, "matches? not implemented for #{self.class}"
      end
      def sync!(broker)
        raise NotImplementedError, "sync!(broker) not implemented for #{self.class}"
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