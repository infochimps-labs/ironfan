module Ironfan
  module ChefServer

    class Node < Ironfan::Provider::Resource
    end

    class Role < Ironfan::Provider::Resource
    end

    class Client < Ironfan::Provider::Resource
    end

    class Connection < Ironfan::Provider::Connection
      collection :nodes, Node

      def discover!
        discover_nodes!
        discover_clients!
      end
      
      # Walk the list of chef nodes and
      # * vivify the server,
      # * associate the chef node
      # * if the chef node knows about its instance id, memorize that for lookup
      #   when we discover cloud instances.
      def discover_nodes!
        pp "Would discover resources nodes for #{self.class} here, but chickening out instead"
        #raise NotImplementedError, "#{self.class}.discover_nodes! not written yet"
      end
      
      # Walk the list of servers, asking each to discover its chef client.
      def discover_clients!
        pp "Would discover resources clients for #{self.class} here, but chickening out instead"
        #raise NotImplementedError, "#{self.class}.discover_clients! not written yet"
      end
    end

  end
end