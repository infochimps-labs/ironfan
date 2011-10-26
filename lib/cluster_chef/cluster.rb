module ClusterChef
  #
  # A cluster has many facets. Any setting applied here is merged with the facet
  # at resolve time; if the facet explicitly sets any attributes they will win out.
  #
  class Cluster < ClusterChef::ComputeBuilder
    attr_reader :facets, :undefined_servers

    def initialize clname, attrs={}
      super(clname.to_sym, attrs)
      @facets            = Mash.new
      @chef_roles        = []
      create_cluster_role
    end

    def cluster
      self
    end

    def cluster_name
      name
    end

    # The auto-generated role for this cluster.
    # Instance-evals the given block in the context of that role
    #
    # @example
    #   cluster_role do
    #     override_attributes({
    #       :time_machine => { :transition_speed => 88 },
    #     })
    #   end
    #
    # @return [Chef::Role] The auto-generated role for this facet.
    def cluster_role(&block)
      @cluster_role.instance_eval( &block ) if block_given?
      @cluster_role
    end
    def main_role(&block) ; cluster_role(&block) ; end

    #
    # Retrieve or define the given facet
    #
    # @param [String] facet_name -- name of the desired facet
    # @param [Hash] attrs -- attributes to configure on the object
    # @yield a block to execute in the context of the object
    #
    # @return [ClusterChef::Facet]
    #
    def facet(facet_name, attrs={}, &block)
      facet_name = facet_name.to_sym
      @facets[facet_name] ||= ClusterChef::Facet.new(self, facet_name)
      @facets[facet_name].configure(attrs, &block)
      @facets[facet_name]
    end

    def has_facet? facet_name
      @facets.include?(facet_name)
    end

    def find_facet(facet_name)
      @facets[facet_name] or raise("Facet '#{facet_name}' is not defined in cluster '#{cluster_name}'")
    end

    # All servers in this facet, sorted by facet name and index
    #
    # @return [ClusterChef::ServerSlice] slice containing all servers
    def servers
      svrs = @facets.sort.map{|name, facet| facet.servers.to_a }
      ClusterChef::ServerSlice.new(self, svrs.flatten)
    end

    #
    # A slice of a cluster:
    #
    # If +facet_name+ is nil, returns all servers.
    # Otherwise, takes slice (given by +*args+) from the requested facet.
    #
    # @param [String] facet_name -- facet to slice (or nil for all in cluster)
    # @param [Array, String] slice_indexes -- servers in that facet (or nil for all in facet).
    #   You must specify a facet if you use slice_indexes.
    #
    # @return [ClusterChef::ServerSlice] the requested slice
    def slice facet_name=nil, slice_indexes=nil
      return ClusterChef::ServerSlice.new(self, self.servers) if facet_name.nil?
      find_facet(facet_name).slice(slice_indexes)
    end

    def to_s
      "#{super[0..-3]} @facets=>#{@facets.keys.inspect}}>"
    end

    def reverse_merge! other_cluster
      @settings.reverse_merge! other_cluster.to_hash
      @settings[:run_list] += other_cluster.run_list
      @settings[:chef_attributes].reverse_merge! other_cluster.chef_attributes
      cloud.reverse_merge! other_cluster.cloud
      self
    end

    def resolve!
      set_default_security_group
      cloud.keypair(cluster_name) if cloud.keypair.nil?
      @facets.values.each(&:resolve!)
    end

    def security_groups
      cloud.security_groups
    end

  protected

    def set_default_security_group
      cluster_name = self.cluster_name # hack variable into scope of folllowing block
      cloud.security_group(cluster_name){ authorize_group(cluster_name) }
    end

    # Creates a chef role named for the facet
    def create_cluster_role
      @cluster_role_name = "#{name}_cluster"
      @cluster_role      = new_chef_role(@cluster_role_name, cluster)
      role(@cluster_role_name)
    end

  end
end
