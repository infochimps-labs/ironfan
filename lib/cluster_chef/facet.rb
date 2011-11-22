module ClusterChef
  class Facet < ClusterChef::ComputeBuilder
    attr_reader :cluster
    has_keys  :instances

    def initialize cluster, facet_name, attrs={}
      super(facet_name.to_sym, attrs)
      @cluster    = cluster
      @servers    = Mash.new
      @chef_roles = []
      @settings[:instances] ||= 0
      create_facet_role
      create_facet_security_group unless attrs[:no_security_group]
    end

    def cluster_name
      cluster.name
    end

    def facet_name
      name
    end

    # The auto-generated role for this facet.
    # Instance-evals the given block in the context of that role,
    #
    # @example
    #   facet_role do
    #     override_attributes({
    #       :time_machine => { :transition_speed => 88 },
    #     })
    #   end
    #
    # @return [Chef::Role] The auto-generated role for this facet.
    def facet_role(&block)
      @facet_role.instance_eval( &block ) if block_given?
      @facet_role
    end

    def assign_volume_ids(volume_name, *volume_ids)
      volume_ids.flatten.zip(servers).each do |volume_id, server|
        server.volume(volume_name){ volume_id(volume_id) } if server
      end
    end

    #
    # Retrieve or define the given server
    #
    # @param [Integer] idx  -- the index of the desired server
    # @param [Hash] attrs -- attributes to configure on the object
    # @yield a block to execute in the context of the object
    #
    # @return [ClusterChef::Facet]
    #
    def server(idx, attrs={}, &block)
      idx = idx.to_i
      @servers[idx] ||= ClusterChef::Server.new(self, idx)
      @servers[idx].configure(attrs, &block)
      @servers[idx]
    end

    # if the server has been added to this facet or is in range
    def has_server? idx
      (idx.to_i < instances) || @servers.include?(idx.to_i)
    end

    #
    # Slicing
    #

    # All servers in this facet
    #
    # @return [ClusterChef::ServerSlice] slice containing all servers
    def servers
      slice(indexes)
    end

    #
    # A slice of servers from this facet, in index order
    #
    # If +slice_indexes+ is nil, returns all servers.
    # Otherwise, takes slice (given by +*args+) from the requested facet.
    #
    # @param [Array, String] slice_indexes -- servers in that facet (or nil for all in facet).
    #
    # @return [ClusterChef::ServerSlice] the requested slice
    def slice(slice_indexes=nil)
      slice_indexes = self.indexes if slice_indexes.blank?
      slice_indexes = indexes_from_intervals(slice_indexes) if slice_indexes.is_a?(String)
      svrs = Array(slice_indexes).map(&:to_i).sort!.select{|idx| has_server?(idx) }.map{|idx| server(idx) }
      ClusterChef::ServerSlice.new(self.cluster, svrs)
    end

    # all valid server indexes
    def valid_indexes
      (0 ... instances).to_a # note the '...'
    end

    # indexes in the 0...instances range plus bogus ones that showed up
    # (probably from chef or fog)
    def indexes
      [@servers.keys, valid_indexes].flatten.compact.uniq.sort
    end

    #
    # Resolve:
    #
    def resolve!
      servers.each(&:resolve!)
    end

  protected

    def create_facet_security_group
      cloud.security_group("#{cluster_name}-#{facet_name}")
    end

    # Creates a chef role named for the facet
    def create_facet_role
      @facet_role_name = "#{cluster_name}_#{facet_name}"
      @facet_role      = new_chef_role(@facet_role_name, cluster, self)
      role(@facet_role_name, :last)
    end

    #
    # Given a string enumerating indexes to select returns a flat array of
    # indexes. The indexes will be unique but in an arbitrary order.
    #
    # @example
    #   facet = ClusterChef::Facet.new('foo', 'bar')
    #   facet.indexes_from_intervals('1,2-3,8-9,7') # [1, 2, 3, 8, 9, 7]
    #   facet.indexes_from_intervals('1,3-5,4,7')   # [1, 3, 4, 5, 7]
    #
    def indexes_from_intervals intervals
      intervals.split(",").map do |term|
        if    term =~ /^(\d+)-(\d+)$/ then ($1.to_i .. $2.to_i).to_a
        elsif term =~ /^(\d+)$/       then  $1.to_i
        else  ui.warn("Bad interval: #{term}") ; nil
        end
      end.flatten.compact.uniq
    end

  end
end
