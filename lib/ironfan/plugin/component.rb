require 'chef'
require 'ironfan'
require 'ironfan/plugin/base'
require 'ironfan/dsl/compute'
require 'ironfan/dsl/component'

module Ironfan
  module Plugin
    class Component < Ironfan::Dsl::Component
      include Gorillib::Concern
      include Ironfan::Plugin::Base; register_with Ironfan::Dsl::Compute

      field :cl_names, Whatever
      field :cl_name, Whatever
      field :rlm_name, Whatever
      field :announce_name, Symbol
      field :name, Symbol

      def initialize(attrs, &blk)
        attrs.merge!(cl_names: (attrs[:owner].cluster_names unless attrs[:owner].nil?),
                     rlm_name: (attrs[:owner].realm_name unless attrs[:owner].nil?),
                     cl_name: (attrs[:owner].cluster_name unless attrs[:owner].nil?))
        super attrs, &blk
      end

      def self.plugin_hook owner, attrs, plugin_name, full_name, &blk
        (this = new(attrs.merge(owner: owner, announce_name: plugin_name, name: full_name), &blk))._project(owner)
        this
      end

      def _project(compute)
        compute.component name, self
        project(compute)
      end

      def cluster_name suffix = nil
        suffix.nil? ? cl_name : cl_names.fetch(suffix) 
      end

      def cluster_suffix suffix = nil
        cluster_name(suffix).to_s.gsub(/^#{realm_name}_/, '').to_sym
      end

      def realm_name() rlm_name; end

      def realm_announcements
        (@@realm_announcements ||= {})
      end
      
      def realm_subscriptions component_name
        (@@realm_subscriptions ||= {})[component_name] ||= []
      end

      def self.skip_fields
        [:cl_names, :cl_name, :rlm_name, :announce_name]
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
          _set_discovery(compute, server_cluster, keys)
        else
          Chef::Log.debug("#{cluster_name}: no one announced #{announce_name}. subscribing")
          discover(announce_name){|cluster| _set_discovery(compute, cluster, keys)}
        end
      end

      def _set_discovery compute, cluster, keys
        discovery = {discovers: keys.reverse.inject(cluster){|hsh,key| {key => hsh}}}
        (compute.facet_role || compute.cluster_role).override_attributes(discovery)
        Chef::Log.debug("discovered #{announce_name} for #{cluster_name}: #{discovery}")
      end
    end

    module Announcement
      include Gorillib::Builder

      def _project(compute)
        announce announce_name
        super compute
      end
    end
  end
end
