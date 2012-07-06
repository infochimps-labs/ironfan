module Ironfan
  module Dsl
    class Cluster < Ironfan::Dsl::Compute
      collection :facets,       Ironfan::Dsl::Facet,    :resolution => ->(f) { merge_resolve(f) }

      def initialize(builder_name, attrs={})
        name    builder_name
        super   attrs
      end
    end
  end
end