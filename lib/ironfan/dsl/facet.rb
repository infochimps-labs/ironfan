module Ironfan
  module Dsl
    class Facet < Ironfan::Dsl::Compute
      magic      :instances,    Integer,                :default => 1
      collection :servers,      Ironfan::Dsl::Server,   :resolver => :deep_resolve

      def facet_role()  layer_role;     end
      def fullname()   "#{underlay.fullname}-#{name}"; end

      def expand_servers
        for i in 0..(instances-1) do server(i); end
      end

    end
  end
end