module Ironfan
  #
  # A cluster has many facets. Any setting applied here is merged with the facet
  # at resolve time; if the facet explicitly sets any attributes they will win out.
  #
  class Cluster < Ironfan::ComputeBuilder
    attr_reader :facets, :undefined_servers

    def initialize(name, attrs={})
      super(name.to_sym, attrs)
      @facets            = Mash.new
      @chef_roles        = []
      environment          :_default if environment.blank?
      create_cluster_role
      ui.warn "Stubbing out Cluster security groups"
      #create_cluster_security_group unless attrs[:no_security_group]
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

    #
    # Retrieve or define the given facet
    #
    # @param [String] facet_name -- name of the desired facet
    # @param [Hash] attrs -- attributes to configure on the object
    # @yield a block to execute in the context of the object
    #
    # @return [Ironfan::Facet]
    #
    def facet(facet_name, attrs={}, &block)
      facet_name = facet_name.to_sym
      @facets[facet_name] ||= Ironfan::Facet.new(self, facet_name)
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
    # @return [Ironfan::ServerSlice] slice containing all servers
    def servers
      svrs = @facets.sort.map{|name, facet| facet.servers.to_a }
      Ironfan::ServerSlice.new(self, svrs.flatten)
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
    # @return [Ironfan::ServerSlice] the requested slice
    def slice facet_name=nil, slice_indexes=nil
      return Ironfan::ServerSlice.new(self, self.servers) if facet_name.nil?
      find_facet(facet_name).slice(slice_indexes)
    end

    def to_s
      "#{super[0..-3]} @facets=>#{@facets.keys.inspect}}>"
    end

    #
    # Resolve:
    #
    def resolve!
      facets.values.each(&:resolve!)
    end

  protected

    # Create a security group named for the cluster
    # that is friends with everything in the cluster
    def create_cluster_security_group
      clname = self.name # put it in scope
      cloud.security_group(clname){ authorize_group(clname) }
    end

    # Creates a chef role named for the cluster
    def create_cluster_role
      @cluster_role_name = "#{name}_cluster"
      @cluster_role      = new_chef_role(@cluster_role_name, cluster)
      role(@cluster_role_name, :own)
    end

  end
end
