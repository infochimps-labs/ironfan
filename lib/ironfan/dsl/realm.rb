module Ironfan
  class Dsl

    class Realm < Ironfan::Dsl::Compute
      collection :clusters,       Ironfan::Dsl::Cluster,   :resolver => :deep_resolve

      def initialize(attrs={},&block)
        super
      end

      def cluster(label, attrs={},&blk)
        new_name = [realm_name, label].join('_').to_sym
        cluster = Ironfan::Dsl::Cluster.new(name: new_name, cluster_names: OpenStruct.new)
        (clusters.keys.map{|k| clusters[k]} << cluster).each do |cl|
          cl.cluster_names.new_ostruct_member label
          cl.cluster_names.send "#{label}=", new_name
        end
        cluster.receive!(attrs, &blk)
        super(new_name, cluster)
      end

      def realm_name()        name;   end
    end
  end
end
