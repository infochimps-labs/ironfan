module Ironfan
  class Dsl

    class Cluster < Ironfan::Dsl::Compute
      collection :facets,       Ironfan::Dsl::Facet,   :resolver => :deep_resolve
      include Ironfan::Plugin::Base; register_with Ironfan::Dsl::Realm

      def children
        facets.to_a + components.to_a
      end

      def initialize(attrs={},&block)
        super
        self.cluster_role       Ironfan::Dsl::Role.new(:name => "#{attrs[:name]}-cluster")
        self.realm_name         attrs[:owner].name unless attrs[:owner].nil?
        self.cluster_names      attrs[:owner].cluster_names unless attrs[:owner].nil?
      end

      # Utility method to reference all servers from constituent facets
      def servers
        result = Gorillib::ModelCollection.new(:item_type => Ironfan::Dsl::Server, :key_method => :full_name)
        facets.each {|f| f.servers.each {|s| result << s} }
        result
      end

      def cluster_name
        name
      end

      def self.plugin_hook owner, attrs, plugin_name, full_name, &blk
        owner.cluster(plugin_name, new(attrs.merge(name: full_name, owner: owner)))
        _project cluster, &blk
      end
    end
  end
end
