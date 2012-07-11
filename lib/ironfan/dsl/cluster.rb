module Ironfan
  module Dsl
    class Cluster < Ironfan::Dsl::Compute
      collection :facets,       Ironfan::Dsl::Facet,   :resolver => :deep_resolve

      def cluster_role()        layer_role;     end

      def expand_servers
        facets.each {|facet| facet.expand_servers }
      end

      # Utility class to reference all servers from constituent facets
      def servers
        result = Gorillib::ModelCollection.new(:full_name,Ironfan::Dsl::Server)
        facets.each {|f| f.servers.each {|s| result << s} }
        result
      end

    end
  end
end