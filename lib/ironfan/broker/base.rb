# This module is intended to read in a cluster DSL description, and broker
#   out to the various cloud providers, to control instance life-cycle and
#   handle provider-specific amenities (SecurityGroup, Volume, etc.) for 
#   them.
module Ironfan

  class Broker
    include Gorillib::Builder
    field :ui,                Whatever,       :default => ->{Ironfan.ui}

    field :chef,              Ironfan::Provider::ChefServer,
          :default =>         Ironfan::Provider::ChefServer.new
    collection :providers,    Ironfan::IaasProvider

    # Take in a Dsl::Cluster, return a MachineCollection populated with
    #   all discovered resources that correlate
    def discover!(cluster)
      cluster.expand_servers
      resolved = cluster.resolve

      discover_resources! resolved
      correlate_machines resolved
    end

    def discover_resources!(cluster)
      # Get all relevant chef resources for the cluster.
      chef.discover! cluster

      # Ensure all providers referenced by the DSL are available, and have
      #   them each survey their applicable resources.
      cluster.servers.each {|server| provider(server.selected_cloud.name) }
      providers.each {|p| p.discover! cluster }
    end

    # Correlate servers with Chef resources, and IaaS machines 
    #   and related Provider resources. Create "nonexistent" machines
    #   for each un-satisfied server expectation.
    def correlate_machines(cluster)
      machines = expected_machines(cluster)
      correlate_nodes(machines)
      correlate_instances(cluster,machines)
      machines
    end

    # for all servers, set up a bare machine
    def expected_machines(cluster)
      machines = MachineCollection.new
      cluster.servers.each do |server|
        m = Machine.new
        m.server = server
        machines << m
      end
      machines
    end

    # for all chef nodes that match the cluster,
    #   find a machine that matches and attach,
    #   or make a new machine and mark it :unexpected_node
    def correlate_nodes(machines)
      chef.nodes.each do |node|
        match = machines.select {|m| node.matches? m }.first
        if match.nil?
          match = Machine.new
          match.bogosity = :unexpected_node
          machines << match
        end
        match.node = node
      end
      machines
    end

    # for each provider instance that matches the cluster,
    #   find a machine that matches
    #     attach instance to machine if there isn't one,
    #     or make another and mark both :duplicate_instance
    #   or make a new machine and mark it :unexpected_instance
    def correlate_instances(cluster,machines)
      each_instance_of(cluster) do |instance|
        match = machines.values.select {|m| instance.matches? m }.first
        if match.nil?
          match = Machine.new
          match.bogosity = :unexpected_instance
          machines << match
        end
        if match.instance?
          match.bogosity = :duplicate_instance
          copy = match.dup
          matches << copy
        end
        match.instance = instance
      end
      machines
    end
    def each_instance_of(expect,&block)
      all_instances_of(expect).each {|i| yield i }
    end
    def all_instances_of(expect)
      providers.values.map {|p| p.instances_of(expect) }.flatten
    end

    def sync_to_chef(machines)
      chef.sync!(machines)
    end
    def sync_to_providers(machines)
      providers.each {|p| p.sync!(machines)}
    end

  end

end