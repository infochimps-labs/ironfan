module ClusterChef
  #
  # A cluster has many facets. Any setting applied here is merged with the facet
  # at resolve time; if the facet explicitly sets any attributes they will win out.
  #
  class Cluster < ClusterChef::ComputeBuilder
    attr_reader :facets, :undefined_servers, :roles

    def initialize clname, hsh={}
      super(clname.to_sym, hsh)
      @facets = Mash.new
      @cluster_role_name = "#{clname}_cluster"
      @roles = []
    end

    def cluster
      self
    end

    def cluster_name
      name
    end

    def cluster_role name=nil, &block 
      @cluster_role_name = name if name
      if block_given?
        @cluster_role = Chef::Role.new
        # Do some magic to ensure that the role knows @cluster
        cluster = self
        @cluster_role.instance_eval { @cluster = cluster }

        @cluster_role.instance_eval( &block )
        @cluster_role.name @cluster_role_name
        @facet_role.description "ClusterChef generated facet role for #{cluster_name}" unless @cluster_role.description
        @roles << @cluster_role
      end

      @settings[:run_list] << "role[#{@cluster_role_name}]"
      return @cluster_role
    end
    
    def self.get name
      ClusterChef.cluster(name)
    end

    def facet facet_name, hsh={}, &block
      facet_name = facet_name.to_sym
      @facets[facet_name] ||= ClusterChef::Facet.new(self, facet_name)
      @facets[facet_name].configure(hsh, &block)
      @facets[facet_name]
    end

    def has_facet? facet_name
      @facets.include?(facet_name)
    end

    def find_facet(facet_name)
      @facets[facet_name] or raise("Facet '#{facet_name}' is not defined in cluster '#{cluster_name}'")
    end

    def servers
      svrs = @facets.sort.map{|name, facet| facet.servers.to_a }
      ClusterChef::ServerSlice.new(self, svrs.flatten)
    end

    def slice *args
      return ClusterChef::ServerSlice.new(self, self.servers) if args.empty?
      facet_name = args.shift
      find_facet(facet_name).slice(*args)
    end

    def to_s
      "#{super[0..-3]} @facets=>#{@facets.keys.inspect}}>"
    end

    def use *clusters
      clusters.each do |c|
        other_cluster =  ClusterChef.load_cluster(c)
        reverse_merge! other_cluster
      end
      self
    end

    def reverse_merge! other_cluster
      @settings.reverse_merge! other_cluster.to_hash
      # return self unless other_cluster.respond_to?(:run_list)
      @settings[:run_list] += other_cluster.run_list
      @settings[:chef_attributes].reverse_merge! other_cluster.chef_attributes
      cloud.reverse_merge! other_cluster.cloud
      self
    end

    def resolve!
      cluster_name = self.cluster_name
      cloud.security_group(cluster_name){ authorize_group(cluster_name) }
      cloud.keypair cluster_name         if cloud.keypair.nil?

      @facets.values.each(&:resolve!)
    end

    def security_groups
      cloud.security_groups
    end

  end
end
