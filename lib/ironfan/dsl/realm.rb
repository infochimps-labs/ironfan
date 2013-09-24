module Ironfan
  class Dsl

    class Realm < Ironfan::Dsl::Compute
      collection :clusters,       Ironfan::Dsl::Cluster,   :resolver => :deep_resolve

      def initialize(attrs={},&block)
        super
      end

      def cluster(label, attrs={},&blk)
        new_name = [realm_name, label].join '_'
        cluster = Ironfan::Dsl::Cluster.new(name: new_name)
        cluster.receive!(attrs, &blk)
        super(new_name, cluster)
      end

      def realm_name()        name;   end
      
      def wire_clusters()
        STDERR.puts "wiring!!!"
      end
    end

  end
end
