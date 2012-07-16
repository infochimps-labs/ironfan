# Providers present a lightweight wrapper for various third-party services,
#   such as Chef's node and client APIs, and Amazon's EC2 APIs. This allows
#   Ironfan ask specialized questions (such as whether a given resource 
#   matches
module Ironfan
  module Provider

    #
    # Generic Resource and Connection
    #
    class Resource
      include Gorillib::Builder
      field    :adaptee,        Whatever

      def matches?(machine)
        raise NotImplementedError, "matches? not implemented for #{self.class}"
      end
    end

    class Connection
      include Gorillib::Builder

      def self.receive(obj,&block)
        the_module = case obj[:name]
          when :chef;           Chef
          when :ec2;            Ec2
          when :virtualbox;     VirtualBox
          else;                 raise "Unsupported provider #{obj[:name]}"
          end
        the_module::Connection.new(obj,&block)
      end

      def discover!
        raise NotImplementedError, "discover! not implemented for #{self.class}"
      end
    end

    #
    # Iaas Instance and Connection
    #
    class Instance < Resource
    end
    
    class IaasConnection < Connection
      collection :instances,    Ironfan::Provider::Instance
      def discover_instances!
        raise NotImplementedError, "discover_instances! not implemented for #{self.class}"
      end
    end

  end
end