module ClusterChef
  class Facet < ClusterChef::ComputeBuilder
    attr_reader :cluster, :facet_name
    has_keys  :instances, :facet_role

    def initialize cluster, fct_name, hsh={}
      super(facet_name, hsh)
      @cluster    = cluster
      @facet_name = fct_name
      @servers    = {}
      chef_attributes :cluster_role => facet_name # backwards compatibility
      chef_attributes :facet_name   => facet_name
      facet_role      "#{@cluster.name}_#{facet_name}"
    end

    def slice *args
      return self if args.length == 0
      FacetSlice.new(self, *args)
    end

    def servers
      @servers.values
    end

    def server_by_index index
      @servers[index.to_s]
    end

    def get_node_name index
      "#{cluster_name}-#{facet_name}-#{index}"
    end

    def cluster_name
      cluster.name
    end

    def security_groups
      groups = cloud.security_groups
      @servers.values.each { |s| groups.merge s.security_groups }
      return groups
    end

    #
    # Resolve:
    #
    def resolve!
      clname = @cluster.name
      @settings    = @cluster.to_hash.merge @settings
      cloud.resolve!          @cluster.cloud
      cloud.keypair           clname if cloud.keypair.nil? #.blank?
      cloud.security_group    clname do authorize_group clname end
      cloud.security_group    "#{clname}-#{facet_name}"

      role cluster.cluster_role if cluster.cluster_role
      role self.facet_role if self.facet_role

      @settings[:run_list]        = @cluster.run_list + self.run_list
      @settings[:chef_attributes] = @cluster.chef_attributes.merge(self.chef_attributes)
      chef_attributes :run_list => run_list

      resolve_volumes!
      resolve_servers!
      self
    end

    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
    end

    def resolve_volumes!
      # cluster.volumes.each do |name, vol|
      #   self.volume(name).reverse_merge!(vol)
      # end
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

    def cluster_group
      return "#{cluster_name}-#{facet_name}"
    end
  end

  class FacetSlice < ClusterChef::ComputeBuilder
    attr_reader :cluster, :facet
    has_keys  :instances

    def initialize facet, instance_indexes
      @facet = facet
      @cluster = facet.cluster
      @instance_indexes = instance_indexes
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
      "#{cluster_name}-#{facet_name}-#{index}"
    end

    def cluster_name
      cluster.name
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
