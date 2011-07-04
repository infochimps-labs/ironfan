module ClusterChef
  class Facet < ClusterChef::ComputeBuilder
    attr_reader :cluster
    has_keys  :instances, :facet_role

    def initialize cluster, facet_name, hsh={}
      super(facet_name.to_sym, hsh)
      @cluster    = cluster
      @servers    = {}
      facet_role  "#{cluster_name}_#{name}"
    end

    def cluster_name
      cluster.name
    end

    def slice indexes=nil
      return self if indexes.nil?
      FacetSlice.new(self, indexes)
    end

    def servers
      @servers.values
    end

    def server_by_index index
      @servers[index.to_s]
    end

    def get_node_name index
      "#{cluster_name}-#{name}-#{index}"
    end

    def security_groups
      groups = cloud.security_groups
      @servers.values.each{|s| groups.merge s.security_groups }
      return groups
    end

    #
    # Resolve:
    #
    def resolve!
      @settings    = cluster.to_hash.merge @settings
      cluster_name = self.cluster_name
      cloud.resolve! cluster.cloud
      cloud.keypair  cluster_name if cloud.keypair.nil?
      cloud.security_group(cluster_name){ authorize_group(cluster_name) }
      cloud.security_group "#{cluster_name}-#{name}"

      role cluster.cluster_role if cluster.cluster_role
      role self.facet_role      if self.facet_role

      @settings[:run_list]        = cluster.run_list + self.run_list
      @settings[:chef_attributes] = cluster.chef_attributes.merge(self.chef_attributes)
      chef_attributes :run_list => run_list

      resolve_volumes!
      resolve_servers!

      self
    end

    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
    end

    def resolve_volumes!
      cluster.volumes.each do |name, vol|
        self.volume(name).reverse_merge!(vol)
      end
    end

    def resolve_servers!
      # Create facets not explicitly defined
      instances.times do |index|
        facet_index = index.to_s

        server facet_index unless @servers[facet_index]
      end

      servers.each do |s|
        s.resolve!
      end
    end

    def server index, &block
      facet_index = index.to_s
      @servers[facet_index] ||= ClusterChef::Server.new(self, facet_index)
      @servers[facet_index].instance_eval(&block) if block
      @servers[facet_index]
    end

    def has_server? index
      return @servers.member? index.to_s
    end
  end

  class FacetSlice < ClusterChef::ComputeBuilder
    attr_reader :cluster, :facet
    has_keys  :instances

    def initialize facet, instance_indexes
      @facet = facet
      @cluster = facet.cluster
      @instance_indexes = instance_indexes.to_s
    end

    def parse_indexes
      indexes = []

      @instance_indexes.split(",").each do |term|
        if term =~ /(\d+)-(\d+)/
          $1.to_i.upto($2.to_i) do |i|
            indexes.push i.to_s
          end
        else
          indexes.push term
        end
      end
      indexes.sort!.uniq!

      @servers = {}
      indexes.each do |idx|
        svr = facet.server_by_index idx
        @servers[idx] = svr if svr
      end
    end

    def servers
      parse_indexes unless @servers
      @servers.values
    end

    def server_by_index index
      parse_indexes unless @servers
      @servers[index.to_s]
    end

    def get_node_name index
      "#{cluster_name}-#{facet.name}-#{index}"
    end

    def security_groups
      cluster.security_groups
    end


    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
    end

    def resolve_servers!
      facet.resolve_servers!
    end

    def server index, &block
      parse_indexes unless @servers

      facet_index = index.to_s
      @servers[facet_index] ||= ClusterChef::Server.new(self, facet_index)
      @servers[facet_index].instance_eval(&block) if block
      @servers[facet_index]
    end
  end
end
