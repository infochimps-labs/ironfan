module Ironfan
  class Dsl

    class Realm < Ironfan::Dsl::Compute
      collection :clusters,       Ironfan::Dsl::Cluster,   :resolver => :deep_resolve

      magic :cluster_suffixes,    Whatever

      def initialize(attrs={},&block)
        cluster_names({})
        cluster_suffixes({})
        super
      end

      def cluster(label, attrs={},&blk)
        new_name = [realm_name, label].join('_').to_sym
        cluster = Ironfan::Dsl::Cluster.new(name: new_name, cluster_names: {})
        cluster_names[label] = new_name
        cluster_suffixes[label] = label
        (clusters.keys.map{|k| clusters[k]} << cluster).each do |cl|
          cl.cluster_names cluster_names
        end
        cluster.receive!(attrs, &blk)
        super(new_name, cluster)
      end

      def realm_name()        name;   end
    end
  end
end
