module Ironfan
  class Dsl
    class Component < Ironfan::Dsl
      include Gorillib::Builder
      include Gorillib::Concern
      include Ironfan::Plugin::Base; register_with Ironfan::Dsl::Compute

      field :cluster_name, Symbol
      field :facet_name, Symbol
      field :realm_name, Symbol
      field :name, Symbol

      def initialize(attrs, &blk)
        attrs.merge!(facet_name: (attrs[:owner].name unless attrs[:owner].nil? or not attrs[:owner].is_a?(Facet)),
                     cluster_name: (attrs[:owner].cluster_name unless attrs[:owner].nil?),
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
        realm_announcements[[realm_name, component_name]] = [cluster_name, facet_name]
        realm_subscriptions(component_name).each{|blk| blk.call(cluster_name, facet_name)}
      end

      def discover(component_name, &blk)
        if already_announced = realm_announcements[[realm_name, component_name]]
          yield *already_announced
        else
          Chef::Log.debug("#{cluster_name}: no one announced #{announce_name}. subscribing")
          realm_subscriptions(component_name) << blk
        end
      end
    end

    module Discovery
      include Gorillib::Builder
      extend Gorillib::Concern

      magic :server_cluster, Symbol
      magic :bidirectional, :boolean, default: false

      (@_dependencies ||= []) << Gorillib::Builder

      module ClassMethods
        def default_to_bidirectional default=true
          magic :bidirectional, :boolean, default: default
        end
      end

      def set_discovery compute, keys
        if server_cluster
          wire_to(compute, full_server_cluster, keys)
        else
          # I'm defanging automatic discovery for now.
          raise StandardError.new("must explicitly specify a server_cluster for discovery")
          # discover(announce_name) do |cluster_name, facet_name|
          #   wire_to(compute, [cluster_name, facet_name].join('-'), keys)
          # end
        end
      end

      def wire_to(compute, full_server_cluster_v, keys)
        discovery = {discovers: keys.reverse.inject(full_server_cluster_v){|hsh,key| {key => hsh}}}
        (compute.facet_role || compute.cluster_role).override_attributes(discovery)

        client_group_v = client_group(compute)
        server_group_v = security_group(full_server_cluster_v)

        group_edge(compute, client_group_v, :authorized_by_group, server_group_v)
        group_edge(compute, client_group_v, :authorize_group,     server_group_v) if bidirectional

        Chef::Log.debug("discovered #{announce_name} for #{cluster_name}: #{discovery}")
      end

      protected

      def client_group(compute)
        security_group(compute.cluster_name, (compute.name if compute.is_a?(Facet)))
      end
      
      def full_server_cluster
        "#{realm_name}_#{server_cluster}"
      end

      def group_edge(cloud, group_1, method, group_2)
        cloud.security_group(group_1).send(method, group_2)
        Chef::Log.debug("component.rb: allowing access from security group #{group_1} to #{group_2}")
      end

      def security_group(*target_components)
        target_components.compact.join('-')
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
