require 'ironfan/dsl/realm'
require 'ironfan/dsl/cluster'
require 'ironfan/plugin/compute'

module Ironfan
  class Dsl
    class ClusterTemplate < Cluster
      include ComputeTemplate
      include Ironfan::Plugin::Base; register_with Ironfan::Dsl::Realm

      def self.plugin_hook owner, attrs, plugin_name, full_name, &blk
        owner.cluster(plugin_name, new(attrs.merge(name: full_name, owner: owner), &blk))
        _project cluster, &blk
      end
    end
  end
end
