module Ironfan
  module Provider

    #
    # Generic Resource and Connection
    #
    class Resource
      include Gorillib::Builder
#       field :provider,          Ironfan::Provider::Connection
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
      field    :native, Whatever

      def initialize(fog_server=nil,*args,&block)
        super(*args,&block)
        self.native = fog_server
        self
      end

      def key_method()  :object_id;     end
    end
    
    class IaasConnection < Connection
      collection :instances,    Ironfan::Provider::Instance
      def discover_machines!
        raise NotImplementedError, "discover_machines! not implemented for #{self.class}"
      end
    end

  end
end