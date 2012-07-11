# This class is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers to survey the existing machines and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan
  module Provider

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
    
    require 'ironfan/provider/chef'

    class Machine < Resource
      field :expectation,       Ironfan::Dsl::Server
      field :chef_node,         Ironfan::ChefServer::Node
      field :chef_client,       Ironfan::ChefServer::Client
    end
    
    class IaasConnection < Connection
      collection :machines,     Ironfan::Provider::Machine
      def discover_machines!
        pp "Would discover resources for #{self.class} here, but chickening out instead"
#         raise NotImplementedError, "discover_machines! not implemented for #{self.class}"
      end
    end

  end
end