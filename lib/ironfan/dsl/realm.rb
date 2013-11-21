module Ironfan
  class Dsl

    class Realm < Ironfan::Dsl::Compute
      collection :clusters,       Ironfan::Dsl::Cluster,   :resolver => :deep_resolve

      def children
        clusters.to_a
      end

      magic :cluster_suffixes,    Whatever

      def initialize(attrs={},&block)
        cluster_names({})
        realm_name attrs[:name] if attrs[:name]
        super
      end

      def cluster(label, attrs={},&blk)
        new_name = [realm_name, label].join('_').to_sym

        if clusters.keys.include? new_name
          clusters[new_name].tap do |cl|
            cl.receive!(attrs)
            cl.instance_eval(&blk) if block_given?
          end
        else
          cluster = Ironfan::Dsl::Cluster.new(name: new_name, owner: self, cluster_names: cluster_names)
          cluster_names[label] = new_name
          cluster.receive!(attrs, &blk)
          super(new_name, cluster)
        end
      end
    end
  end
end
