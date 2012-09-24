module Ironfan
  class Provider

    class ChefServer < Ironfan::Provider
      self.handle = :chef

      def self.resources
        [ Client, Node, Role ]
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
