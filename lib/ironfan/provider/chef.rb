module Ironfan
  module Provider
    module ChefServer

      # 
      # Resources
      #
      class Node < Ironfan::Provider::Resource
        field    :native,       Whatever
        delegate :name,         :to => :native
        
        def initialize(chef_node,*args,&block)
          super(*args,&block)
          self.native = chef_node
          self
        end
        
        def matches?(machine)
          machine.expected.full_name == name 
        end

        def display_values(style)
          {
            "Chef?" =>          native.nil? ? "no" : "yes"
          }
        end

      end

      class Role < Ironfan::Provider::Resource
      end

      class Client < Ironfan::Provider::Resource
        field    :native,       Whatever
        delegate :name,         :to => :native
      end

      # 
      # Connection
      #
      class Connection < Ironfan::Provider::Connection
        collection :nodes,      Ironfan::Provider::ChefServer::Node
        collection :clients,    Ironfan::Provider::ChefServer::Client

        def discover!(cluster) 
          discover_nodes! cluster
          discover_clients! cluster
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
        
        def discover_clients!(cluster)
          return clients unless clients.empty?
          # Oh for fuck's sake -- the key used to index clients changed from
          # 'clientname' in 0.10.4-and-prev to 'name' in 0.10.8. Rather than index
          # both 'clientname' and 'name', they switched it -- so we have to fall
          # back.  FIXME: While the Opscode platform is 0.10.4 I have clientname
          # first (sorry, people of the future). When it switches to 0.10.8 we'll
          # reverse them (suck it people of the past).
          chef_search = Chef::Search::Query.new
          api_clients,x,y = chef_search.search(:client, "clientname:#{cluster.name}-*") ; api_clients.compact!
          api_clients,x,y = chef_search.search(:client, "name:#{cluster.name}-*") if api_clients.blank?
          api_clients.each do |api_client|
            # Sometimes the server returns nil results on recently-expired clients
            next if api_client.nil?
            # Return values from Chef::Search seem to be inconsistent across chef
            # versions (sometimes a hash, sometimes an object)
            api_client = Chef::ApiClient.json_create(api_client) unless api_client.is_a?(Chef::ApiClient)
            clients << Client.new(:native => api_client)
          end
          clients
        end
      end

    end
  end
end