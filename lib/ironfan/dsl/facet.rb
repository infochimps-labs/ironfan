module Ironfan
  module Dsl
    class Facet < Ironfan::Dsl::Compute
      magic      :instances,    Integer,                :default => 1
      collection :servers,      Ironfan::Dsl::Server,   :resolver => :deep_resolve
      field      :cluster_name, String

      def initialize(attrs={},&block)
        self.cluster_name = attrs[:owner].name unless attrs[:owner].nil?
        super
      end

      def fullname()    "#{cluster_name}-#{name}";      end
      def facet_role()  layer_role;                     end

      def expand_servers
        for i in 0..(instances-1) do server(i); end
      end

    end
  end
end