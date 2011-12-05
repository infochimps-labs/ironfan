require File.expand_path('cluster_chef.rb', File.dirname(__FILE__))
module ClusterChef

  #
  # ClusterChef::Discovery --
  #
  # Allow nodes to discover the location for a given component at runtime, adapting
  # when new components announce.
  #
  # Operations:
  #
  # * announce a component. A timestamp records the last announcement.
  # * discover all servers announcing the given component.
  # * discover the most recent server for that component.
  #
  #
  module Discovery

    #
    # Announce that you provide the given component in some realm (by default,
    # this node's cluster).
    #
    # @param [Symbol] sys    name of the system
    # @param [Symbol] subsys name of the subsystem
    # @param [Hash] opts extra attributes to pass to the component object
    # @option opts [String] :realm Offer the component within this realm -- by
    #   default, the current node's cluster
    #
    def announce(sys, subsys=nil, opts={})
      opts           = Mash.new(opts)
      opts[:realm] ||= default_realm
      component = Component.new(run_context, sys, subsys, opts)
      Chef::Log.info("Announcing component #{component.fullname}")
      node.set[:discovery][component.fullname] = component.to_hash
      node_changed!
      component
    end

    # Find all announcements for the given system
    #
    # @example
    #   discover_all(:cassandra, :seeds)           # all cassandra seeds for current cluster
    #   discover_all(:cassandra, :seeds, 'bukkit') # all cassandra seeds for 'bukkit' cluster
    #
    # @return [ClusterChef::Component] component from server to most recently-announce
    def discover_all(sys, subsys=nil, realm=nil)
      realm ||= default_realm
      component_name = ClusterChef::Component.fullname(realm, sys, subsys)
      #
      servers = discover_all_nodes(component_name)
      servers.map do |server|
        hsh = server[:discovery][component_name]
        hsh[:realm] = realm
        ClusterChef::Component.new(server, sys, subsys, hsh)
      end
    end

    # Find the latest announcement for the given system
    #
    # @example
    #   discover(:redis, :server)             # redis server for current cluster
    #   discover(:redis, :server, 'uploader') # redis server for 'uploader' realm
    #
    # @return [ClusterChef::Component] component from server to most recently-announce
    def discover(sys, subsys=nil, realm=nil)
      discover_all(sys, subsys, realm).last
    end

    def default_realm
      node[:cluster_name]
    end

  protected
    #
    # all nodes that have announced the given component, in ascending order of
    # timestamp (most recent is last)
    #
    def discover_all_nodes(component_name)
      all_servers = search(:node, "discovery:#{component_name}" ) rescue []
      if all_servers.empty?
        Chef::Log.warn("No node announced for '#{component_name}'")
        return []
      end
      all_servers.reject!{|server| server.name == node.name}  # remove this node...
      all_servers << node if node[:announces][component_name] # & use a fresh version
      all_servers.sort_by{|server| server[:discovery][component_name][:timestamp] }
    end

  end
end
