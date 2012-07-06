module Ironfan
  module Dsl
    class Facet < Ironfan::Dsl::Compute
      magic      :instances,    Integer
      magic      :cluster,      Whatever

      def facet_role()    layer_role;     end

    end
  end
end