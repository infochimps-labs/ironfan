module Ironfan
  class Dsl

    class Realm < Ironfan::Dsl::Compute
      collection :clusters,       Ironfan::Dsl::Cluster,   :resolver => :deep_resolve

      def initialize(attrs={},&block)
        super
      end

      def cluster(label, attrs={},&blk)
        new_name = [realm_name, label].join('_').to_sym
        cluster = Ironfan::Dsl::Cluster.new(name: new_name, clusters: OpenStruct.new)
        (clusters.keys.map{|k| clusters[k]}.to_a + [cluster]).
          each{|cl| cl.clusters.new_ostruct_member label; cl.clusters.send "#{label}=", new_name}
        cluster.receive!(attrs, &blk)
        super(new_name, cluster)
      end

      def realm_name()        name;   end
    end
  end
end
