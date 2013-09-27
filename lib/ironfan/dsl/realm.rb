module Ironfan
  class Dsl

    class Realm < Ironfan::Dsl::Compute
      collection :clusters,       Ironfan::Dsl::Cluster,   :resolver => :deep_resolve

      magic :cluster_suffixes,    Whatever

      def initialize(attrs={},&block)
        cluster_names({})
        realm_name attrs[:name] if attrs[:name]
        super
      end

      def cluster(label, attrs={},&blk)
        new_name = [realm_name, label].join('_').to_sym
        cluster = Ironfan::Dsl::Cluster.new(name: new_name, owner: self, cluster_names: cluster_names)
        cluster_names[label] = new_name
        cluster.receive!(attrs, &blk)
        super(new_name, cluster)
      end

      def cluster_name suffix
        clusters.fetch([realm_name, suffix.to_s].join('_').to_sym).name.to_sym
      end
      
      def cluster_suffix suffix
        clusters.
          fetch([realm_name, suffix.to_s].join('_').to_sym).name.to_s.
          gsub(/^#{realm_name}_/, '').to_sym
      end
    end
  end
end
