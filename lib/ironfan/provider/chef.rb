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

      #
      # Utility functions
      #
      def self.post_rest(type, content, options={})
        params = [ Chef::Config[:chef_server_url] ]
        if options[:client]
          params << options[:client].name
          params << options[:client].key_filename
        end
        Chef::REST.new(*params).post_rest(type,content)
      end

      def self.search(*params,&block)
        Chef::Search::Query.new.search(*params,&block)
      end
    end

  end
end