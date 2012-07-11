module Ironfan
  module ChefServer

    class Node < Ironfan::Provider::Resource
      field    :native, Whatever
      delegate :name,   :to => :native
      
      def initialize(chef_node,*args,&block)
        super(*args,&block)
        self.native = chef_node
        self
      end
    end

    class Role < Ironfan::Provider::Resource
    end

    class Client < Ironfan::Provider::Resource
    end

    class Connection < Ironfan::Provider::Connection
      collection :nodes, Ironfan::ChefServer::Node

      def discover!(cluster)
        discover_nodes! cluster
        discover_clients!
      end
      
      def discover_nodes!(cluster)
        return nodes unless nodes.empty?
        Chef::Search::Query.new.search(:node,"cluster_name:#{cluster.name}") do |n|
          nodes << Node.new(n) unless n.blank?
        end
        nodes
      end
      
      def find_node(server)
        nodes[server.full_name]
      end
      
      # Walk the list of servers, asking each to discover its chef client.
      def discover_clients!
        pp "Would discover clients resources for #{self.class} here, but chickening out instead"
        #raise NotImplementedError, "#{self.class}.discover_clients! not written yet"
      end
    end

  end
end