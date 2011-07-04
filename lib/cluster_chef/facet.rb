module ClusterChef
  class Facet < ClusterChef::ComputeBuilder
    attr_reader :cluster
    has_keys  :instances, :facet_role

    def initialize cluster, facet_name, hsh={}
      super(facet_name.to_sym, hsh)
      @cluster    = cluster
      @servers    = Mash.new
      facet_role  "#{cluster_name}_#{name}"
      @settings[:instances] ||= 1
      p [self, cluster, facet_name]
    end

    def cluster_name
      cluster.name
    end

    def server idx, hsh={}, &block
      idx = idx.to_i
      @servers[idx] ||= ClusterChef::Server.new(self, idx)
      @servers[idx].configure(hsh, &block)
      @servers[idx]
    end

    def servers
      ClusterChef::ServerSlice.new(cluster, slice(indexes) )
    end

    def all_servers
      ClusterChef::ServerSlice.new(cluster, slice(all_indexes) )
    end

    # all valid server indexes
    def indexes
      (0 ... instances).to_a # note the '...'
    end

    # indexes in the 0...instances range plus bogus ones that showed up
    # (probably from chef or fog)
    def all_indexes
      [@servers.keys, indexes].flatten.compact.uniq.sort
    end

    # if the server has been added to this facet or is in range
    def has_server? idx
      (idx.to_i < instances) || @servers.include?(idx.to_i)
    end

    # servers from this facet, in index order
    def slice( slice_indexes )
      slice_indexes
        .map(&:to_i).sort!
        .map{|idx| server(idx) }
    end

    def slice_by_intervals intervals
      idxs = intervals.split(",").map do |term|
        if    term =~ /^(\d+)-(\d+)$/ then ($1.to_i .. $2.to_i).to_a
        elsif term =~ /^(\d+)$/       then  $1.to_i
        else  warn("Bad interval: #{term}") ; nil
        end
      end.flatten.compact.uniq!
      slice idxs
    end

    # def servers
    #   @servers.values
    # end
    #
    # def server_by_index index
    #   @servers[index.to_s]
    # end
    #
    # def get_node_name index
    #   "#{cluster_name}-#{name}-#{index}"
    # end
    #
    # def security_groups
    #   groups = cloud.security_groups
    #   @servers.values.each{|s| groups.merge s.security_groups }
    #   return groups
    # end
    #
    # #
    # # Resolve:
    # #
    # def resolve!
    #   @settings    = cluster.to_hash.merge @settings
    #   cluster_name = self.cluster_name
    #   cloud.resolve! cluster.cloud
    #   cloud.keypair  cluster_name if cloud.keypair.nil?
    #   cloud.security_group(cluster_name){ authorize_group(cluster_name) }
    #   cloud.security_group "#{cluster_name}-#{name}"
    #
    #   role cluster.cluster_role if cluster.cluster_role
    #   role self.facet_role      if self.facet_role
    #
    #   @settings[:run_list]        = cluster.run_list + self.run_list
    #   @settings[:chef_attributes] = cluster.chef_attributes.merge(self.chef_attributes)
    #   chef_attributes :run_list => run_list
    #
    #   resolve_volumes!
    #   resolve_servers!
    #
    #   self
    # end
    #
    # def to_hash_with_cloud
    #   to_hash.merge({ :cloud => cloud.to_hash, })
    # end
    #
    # def resolve_volumes!
    #   cluster.volumes.each do |name, vol|
    #     self.volume(name).reverse_merge!(vol)
    #   end
    # end
    #
    # def resolve_servers!
    #   # Create facets not explicitly defined
    #   instances.times do |index|
    #     facet_index = index.to_s
    #
    #     server facet_index unless @servers[facet_index]
    #   end
    #
    #   servers.each do |s|
    #     s.resolve!
    #   end
    # end
    #

  end

  # class FacetSlice < ClusterChef::ComputeBuilder
  #   attr_reader :cluster, :facet
  #   has_keys  :instances
  #
  #   def initialize facet, instance_indexes
  #     @facet = facet
  #     @cluster = facet.cluster
  #     @instance_indexes = instance_indexes.to_s
  #   end
  #
  #
  #   def servers
  #     parse_indexes unless @servers
  #     @servers.values
  #   end
  #
  #   def server_by_index index
  #     parse_indexes unless @servers
  #     @servers[index.to_s]
  #   end
  #
  #   def get_node_name index
  #     "#{cluster_name}-#{facet.name}-#{index}"
  #   end
  #
  #   def security_groups
  #     cluster.security_groups
  #   end
  #
  #   def to_hash_with_cloud
  #     to_hash.merge({ :cloud => cloud.to_hash, })
  #   end
  #
  #   def resolve_servers!
  #     facet.resolve_servers!
  #   end
  #
  #   def server index, &block
  #     parse_indexes unless @servers
  #
  #     facet_index = index.to_s
  #     @servers[facet_index] ||= ClusterChef::Server.new(self, facet_index)
  #     @servers[facet_index].instance_eval(&block) if block
  #     @servers[facet_index]
  #   end
  # end
end
