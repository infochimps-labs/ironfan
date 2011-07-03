module ClusterChef
  #
  # A cluster has many facets. Any setting applied here is merged with the facet
  # at resolve time; if the facet explicitly sets any attributes they will win out.
  #
  class Cluster < ClusterChef::ComputeBuilder
    attr_reader :facets, :undefined_servers
    has_keys :cluster_role

    def initialize clname
      super(clname)
      @facets = {}
      chef_attributes  :cluster_name => clname
      cluster_role "#{clname}_cluster"
    end

    def facet facet_name, &block
      @facets[facet_name] ||= ClusterChef::Facet.new(self, facet_name)
      @facets[facet_name].instance_eval(&block) if block
      @facets[facet_name]
    end

    def has_facet? facet_name
      return @facets.member?(facet_name)
    end

    def slice *args
      return self if args.length == 0
      facet_name = args.shift
      unless @facets[facet_name]
        $stderr.puts "Facet '#{facet_name}' is not defined in cluster '#{cluster_name}'"
        exit -1
      end
      return @facets[facet_name].slice *args
    end

    def cluster
      self
    end

    def cluster_name
      self.name
    end

    def use *clusters
      clusters.each do |c|
        cluster = c.to_s
        ClusterChef.load_cluster(cluster)
        merge! cluster
      end
      self
    end

    def merge! other_cluster
      if(other_cluster.is_a?(String)) then other_cluster = ClusterChef.cluster(other_cluster) end
      @settings = other_cluster.to_hash.merge @settings
      @settings[:run_list]        = other_cluster.run_list + self.run_list
      @settings[:chef_attributes] = other_cluster.chef_attributes.merge(self.chef_attributes)
      cloud.merge! other_cluster.cloud
      self
    end


    def security_groups
      groups = cloud.security_groups
      @facets.values.each { |f| groups.merge f.security_groups }
      return groups
    end

    def resolve!
      @facets.values.each { |f| f.resolve! }
      discover!
    end

    def servers
      @facets.values.map {|facet| facet.servers }.flatten
    end

    def cluster_group
      return cluster_name
    end

    def fog_servers
      @fog_servers ||= ClusterChef.servers.select {|s| s.groups.index( cluster_group ) && s.state != "terminated" }
    end

    def chef_nodes
      return @chef_nodes if @chef_nodes
      @chef_nodes = []
      Chef::Search::Query.new.search(:node,"cluster_name:#{cluster_name}") do |n|
        next if n.nil? or n.cluster_name != cluster_name
        @chef_nodes.push n unless n.nil?
      end
      @chef_nodes
    end

    def discover!
      # Build a crossover table between what should be, what is in fog
      # and what is in chef.
      node_name_hash = Hash.new { |hash,key| hash[key] = [nil,nil,nil] }
      servers.each { |s|
        node_name_hash[ s.chef_node_name ][0] = s
      }

      # The only way to link up to an actual instance is throug
      # what Ohai discovered about the node in chef, so we need
      # to build an instance_id to node_name map

      aws_instance_hash = {}
      chef_nodes.each do |n|
        node_name_hash[ n.node_name ][1] = n
        aws_instance_hash[ n.ec2.instance_id ] = n.node_name if n.ec2.instance_id
      end

      fog_servers.each do |s|
        # If the fog server is tagged with cluster/facet/index, then try
        # to locate the corresponding machine in the cluster def and get
        # its chef_node_name
        if s.tags["cluster"] && s.tags["facet"] && s.tags["index"]
          if has_facet?( s.tags["facet"])
            f = facet(s.tags["facet"])
            if f.has_server?( s.tags["index"] )
              nn = f.server(s.tags["index"]).chef_node_name
            end
          end
        end

        # Otherwise, try to get to it through mapping the aws instance id
        # to the chef node name found in the chef node
        nn ||= aws_instance_hash[ s.id ] || s.id

        node_name_hash[ nn ][2] = s
      end

      @undefined_servers = []
      node_name_hash.values.each do |svr,chef_node,fog_svr|
        if svr
          # Note that it is possible that either one of these could be
          # nil. If fog_svr is nil and chef_node is defined, it means
          # that the actual instance has been terminated, but that it
          # did probably exist at one time. When we go to launch the
          # cluster, this node will be rebuilt.

          # If the fog_server is defined, but the chef node is not,
          # it means that someone has started the node but chef has
          # not managed to set things up yet. It also means that someone
          # has worked out a way to map a fog_server to a specific
          # facet_index.
          svr.chef_node = chef_node
          svr.fog_server = fog_svr
        else
          # If we are here, we have discovered some nodes that belong
          # to the cluster but are not actually defined implictly or
          # explicitly by the cluster definition. We could probably
          # try to work out what facet and index they are supposed to
          # be, but I am not sure that it is useful. Instead, we will
          # just collect them into one big bag and we can deal with
          # them as needed later on.
          @undefined_servers.push( { :chef_node => chef_node, :fog_server => fog_svr } )
        end
      end
    end
  end

  # This class represents a loose collection of servers within a cluster, but not necessarily
  # all in the same facet.  They can be started, stopped, launched, killed, etcetera as a group.
  class ClusterSlice < ClusterChef::ComputeBuilder
    attr_reader :cluster
    attr_reader :servers

    def initialize cluster, servers
      @cluster = cluster
      @servers = servers
    end

    def cluster_name
      cluster.name
    end
  end

end
