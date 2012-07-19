module Ironfan
  module Dsl

    class Cluster < Ironfan::Dsl::Compute
      collection :facets,       Ironfan::Dsl::Facet,   :resolver => :deep_resolve

      def initialize(attrs={},&block)
        self.cluster_role       Ironfan::Dsl::Role.new(:name => "#{attrs[:name]}_cluster")
        super
      end

      def expand_servers
        facets.each {|facet| facet.expand_servers }
      end

      # Utility method to reference all servers from constituent facets
      def servers
        result = Gorillib::ModelCollection.new(:item_type => Ironfan::Dsl::Server, :key_method => :fullname)
        facets.each {|f| f.servers.each {|s| result << s} }
        result
      end
    end

  end
end