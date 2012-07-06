module Ironfan
  module Dsl
    class Facet < Ironfan::Dsl::Compute
      magic      :instances,    Integer
      magic      :cluster,      Whatever
      collection :servers,      Ironfan::Dsl::Server, :resolution => ->(f) { merge_resolve(f) }

      def facet_role()    layer_role;     end

    end
  end
end