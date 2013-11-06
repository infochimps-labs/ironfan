require 'ironfan/dsl/facet'
require 'ironfan/plugin/compute'

module Ironfan
  class Dsl
    class FacetTemplate < Facet
      include ComputeTemplate
      include Ironfan::Plugin::Base; register_with Ironfan::Dsl::Cluster

      def self.plugin_hook owner, attrs, plugin_name, full_name, &blk
        facet = owner.facet(plugin_name, new(attrs.merge(name: plugin_name, owner: owner)))
        _project facet, &blk
      end
    end
  end
end
