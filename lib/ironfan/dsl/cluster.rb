module Ironfan
  module Dsl
    class Cluster < Ironfan::Dsl::Compute
      collection :facets,       Ironfan::Dsl::Facet,
          :resolver           => :merge_resolve

      def cluster_role()    layer_role;     end

      def expand_servers
        facets.each_pair {|n,facet| facet.expand_servers }
      end

    end
  end
end