module Ironfan
  class Dsl
    class Component < Ironfan::Dsl
      include Gorillib::Builder
      include Gorillib::Concern
      include Ironfan::Plugin::Base; register_with Ironfan::Dsl::Compute

      field :cluster_name, Symbol
      field :realm_name, Symbol
      field :name, Symbol

      def initialize(attrs, &blk)
        attrs.merge!(cluster_name: (attrs[:owner].cluster_name unless attrs[:owner].nil?),
                     realm_name: (attrs[:owner].realm_name unless attrs[:owner].nil?))
        super attrs, &blk
      end

      def self.plugin_hook owner, attrs, plugin_name, full_name, &blk
        (this = new(attrs.merge(owner: owner, name: full_name), &blk))._project(owner)
        this
      end

      def announce_to node
        node.set['components']["#{cluster_name}-#{name}"]['name'] = name
      end

      def self.to_node
        super.tap do |node|
          node.set['cluster_name'] = cluster_name
        end
      end

      def self.from_node(node = NilCheckDelegate.new(nil))
        cluster_name = node['cluster_name'].to_s
        super(node).tap{|x| x.receive!(cluster_name: cluster_name,
                                       realm_name: cluster_name.split('_').first)}
      end

      def self.announce_name
        plugin_name
      end

      def announce_name
        self.class.announce_name
      end

      def _project(compute)
        compute.component name, self
        project(compute)
      end

      def realm_announcements
        (@@realm_announcements ||= {})
      end
      
      def realm_subscriptions component_name
        (@@realm_subscriptions ||= {})[component_name] ||= []
      end

      def announce(component_name)
        Chef::Log.debug("announced #{announce_name} for #{cluster_name}")
        realm_announcements[[realm_name, component_name]] = cluster_name
        announce_to_subscribers(component_name, cluster_name)
      end

      def announce_to_subscribers(component_name, cluster)
        realm_subscriptions(component_name).each{|blk| blk.call cluster}
      end

      def discover(component_name, &blk)
        if already_announced = realm_announcements[[realm_name, component_name]]
          yield already_announced
        else
          Chef::Log.debug("#{cluster_name}: no one announced #{announce_name}. subscribing")
          discover_by_subscription component_name, &blk
        end
      end

      def discover_by_subscription(component_name, &blk)
        realm_subscriptions(component_name) << blk
      end
    end

    module Discovery
      include Gorillib::Builder

      magic :server_cluster, Symbol

      def set_discovery compute, keys
        if server_cluster
          _set_discovery(compute, full_server_cluster, keys)
        else
          discover(announce_name){|cluster| _set_discovery(compute, cluster, keys)}
        end
      end

      def _set_discovery compute, cluster, keys
        discovery = {discovers: keys.reverse.inject(cluster){|hsh,key| {key => hsh}}}
        (compute.facet_role || compute.cluster_role).override_attributes(discovery)
        Chef::Log.debug("discovered #{announce_name} for #{cluster_name}: #{discovery}")
      end

      protected

      def full_server_cluster
        "#{realm_name}_#{server_cluster}"
      end
    end

    module Announcement
      include Gorillib::Builder

      def _project(compute)
        announce announce_name
        super compute
      end
    end
    def to_manifest
      to_wire.reject{|k,_| _skip_fields.include? k}
    end

    def _skip_fields() skip_fields << :_type; end

    def skip_fields() [] end
  end
end
