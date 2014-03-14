module Ironfan
  class Dsl
    class Realm < Ironfan::Dsl::Compute
      collection :clusters,       Ironfan::Dsl::Cluster,   :resolver => :deep_resolve

      magic :cluster_suffixes,    Whatever

      def self.definitions
        @realms ||= {}
      end

      def self.define(attrs = {}, &blk)
        rlm = new(attrs)
        rlm.receive!({}, &blk)
        definitions[attrs[:name].to_sym] = rlm
      end

      def initialize(attrs = {}, &blk)
        cluster_names Hash.new
        realm_name attrs[:name] if attrs[:name]
        attrs[:environment] = realm_name unless attrs.has_key?(:environment)
        super(attrs, &blk)
      end

      def cluster(label, attrs = {}, &blk)
        if clusters.keys.include? label
          clusters[label].tap do |cl|
            cl.receive! attrs
            cl.instance_eval(&blk) if block_given?
          end
        else
          cluster = Ironfan::Dsl::Cluster.define(name: label, owner: self, cluster_names: cluster_names)
          cluster_names[label] = label
          cluster.receive!(attrs, &blk)
          super(label, cluster)
        end
      end

      def children
        clusters.to_a
      end
    end
  end
end
