module Ironfan
  class Provider

    class ChefServer < Ironfan::Provider
      collection :clients,      Ironfan::Provider::ChefServer::Client
      collection :nodes,        Ironfan::Provider::ChefServer::Node
      collection :roles,        Ironfan::Provider::ChefServer::Role

      def initialize
        super
        @clients =              Ironfan::Provider::ChefServer::Clients.new
        @nodes =                Ironfan::Provider::ChefServer::Nodes.new
        @roles =                Ironfan::Provider::ChefServer::Roles.new
      end

      def self.rest_connect(client=nil)
        params = [ Chef::Config[:chef_server_url] ]
        if client
          params << client.name
          params << client.key_filename
        end
        Chef::REST.new(*params)
      end
      #
      # Discovery
      #
      def load!(machines)
        delegate_to([nodes, clients]) { load! machines }
      end

      def correlate!(machines)
        delegate_to([nodes, clients]) { correlate! machines }
      end

      def validate!(machines)
        delegate_to(nodes) { validate! machines }
      end

      # 
      # Manipulation
      #
      def create_dependencies!(machines)
        delegate_to([clients,nodes]) { create! machines }
      end

      def destroy!(machines)
        delegate_to([nodes, clients]) { destroy! machines }
      end

      def save!(machines)
        delegate_to([nodes, roles]) { save! machines }
      end

    end

  end
end