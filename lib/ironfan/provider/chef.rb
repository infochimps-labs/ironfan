module Ironfan
  class Provider

    class ChefServer < Ironfan::Provider

      #
      # Discovery
      #
      def load!(computers)
        delegate_to([Node, Client]) { load! computers }
      end

      def correlate!(computers)
        delegate_to([Node, Client]) { correlate! computers }
      end

      def validate!(computers)
        delegate_to(Node) { validate! computers }
      end

      # 
      # Manipulation
      #
      def create_dependencies!(computers)
        delegate_to([Client,Node]) { create! computers }
      end

      def destroy!(computers)
        delegate_to([Node, Client]) { destroy! computers }
      end

      def save!(computers)
        delegate_to([Node, Role]) { save! computers }
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