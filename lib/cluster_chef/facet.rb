module ClusterChef
  class Facet < ClusterChef::ComputeBuilder
    attr_reader :cluster,:roles
    has_keys  :instances

    def initialize cluster, facet_name, hsh={}
      super(facet_name.to_sym, hsh)
      @cluster    = cluster
      @servers    = Mash.new
      @facet_role_name = "#{cluster_name}_#{facet_name}"
      @settings[:instances] ||= 0
      @roles = []
    end

    def cluster_name
      cluster.name
    end

    def facet_name
      name
    end

    def facet_role name=nil, &block
      @facet_role_name = name if name
      if block_given?
        @facet_role = Chef::Role.new
        # Do some magic to make it so that the role definition knows @cluster and @facet
        cluster = cluster
        facet = self
        @facet_role.instance_eval{ @facet = facet; @cluster = cluster }
        @facet_role.instance_eval( &block )
        @facet_role.name @facet_role_name
        @facet_role.description "ClusterChef generated facet role for #{cluster_name}-#{facet_name}" unless @facet_role.description
        @roles << @facet_role
      end
      @settings[:run_list] << "role[#{@facet_role_name}]"
      return @facet_role
    end

    def server idx, hsh={}, &block
      idx = idx.to_i
      @servers[idx] ||= ClusterChef::Server.new(self, idx)
      @servers[idx].configure(hsh, &block)
      @servers[idx]
    end

    # if the server has been added to this facet or is in range
    def has_server? idx
      (idx.to_i < instances) || @servers.include?(idx.to_i)
    end

    #
    # Slicing
    #

    def servers
      ClusterChef::ServerSlice.new(cluster, slice(indexes) )
    end

    # servers from this facet, in index order
    def slice(slice_indexes=nil)
      return servers if (slice_indexes.nil?) || (slice_indexes == '')
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

    def indexes_from_intervals intervals
      intervals.split(",").map do |term|
        if    term =~ /^(\d+)-(\d+)$/ then ($1.to_i .. $2.to_i).to_a
        elsif term =~ /^(\d+)$/       then  $1.to_i
        else  warn("Bad interval: #{term}") ; nil
        end
      end.flatten.compact.uniq
    end

    def security_groups
      cloud.security_groups.merge(cluster.security_groups)
    end

    #
    # Resolve:
    #
    def resolve!
      cloud.security_group "#{cluster_name}-#{facet_name}"
      resolve_servers!
      self
    end

    def resolve_servers!
      servers.each(&:resolve!)
    end
  end
end
