module Ironfan
  module Provider
    module Chef
      class Connection < Ironfan::Provider::Connection
        def discover!
          discover_nodes!
          discover_clients!
          #discover_roles!
        end
        
        # Walk the list of chef nodes and
        # * vivify the server,
        # * associate the chef node
        # * if the chef node knows about its instance id, memorize that for lookup
        #   when we discover cloud instances.
        def discover_nodes!
          raise NotImplementedError, "#{self.class}.discover_nodes! not written yet"
        end
        
        # Walk the list of servers, asking each to discover its chef client.
        def discover_clients!
          raise NotImplementedError, "#{self.class}.discover_clients! not written yet"
        end
      end

      class Node
      end

      class Role
      end

      class Client
      end
    end
  end
end