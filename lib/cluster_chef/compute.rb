module ClusterChef
  #
  # Base class allowing us to layer settings for facet over cluster
  #
  class ComputeBuilder < ClusterChef::DslObject
    attr_reader :cloud
    has_keys :name, :chef_attributes, :roles, :run_list, :cloud
    @@role_implications ||= {}

    def initialize builder_name
      super()
      name         builder_name
      run_list     []
      @settings[:chef_attributes] = {}
    end

    # Magic method to produce cloud instance:
    # * returns the cloud instance, creating it if necessary.
    # * executes the block in the cloud's object context
    #
    # @example
    #   # defines a security group
    #   cloud :ec2 do
    #     security_group :foo
    #   end
    #
    # @example
    #   # same effect
    #   cloud.security_group :foo
    #
    def cloud cloud_provider=nil, &block
      raise "Only have ec2 so far" if cloud_provider && (cloud_provider != :ec2)
      @cloud ||= ClusterChef::Cloud::Ec2.new
      @cloud.instance_eval(&block) if block
      @cloud
    end

    # Merges the given hash into
    # FIXME: needs to be a deep_merge
    def chef_attributes hsh={}
      # The DSL attribute for 'chef_attributes' merges not overwrites
      @settings[:chef_attributes].merge! hsh unless hsh.empty? #.blank?
      @settings[:chef_attributes]
    end

    # Adds the given role to the run list, and invokes any role_implications it
    # implies (for instance, the 'ssh' role on an ec2 machine requires port 22
    # be explicity opened.)
    #
    def role role_name
      run_list << "role[#{role_name}]"
      self.instance_eval(&@@role_implications[role_name]) if @@role_implications[role_name]
    end
    # Add the given recipe to the run list
    def recipe name
      run_list << name
    end

    # Some roles imply aspects of the machine that have to exist at creation.
    # For instance, on an ec2 machine you may wish the 'ssh' role to imply a
    # security group explicity opening port 22.
    #
    # FIXME: This feels like it should be done at resolve time
    #
    def role_implication name, &block
      @@role_implications[name] = block
    end

    #
    # This is an outright kludge, awaiting a refactoring of the
    # securit group bullshit
    #
    def setup_role_implications
      role_implication "hadoop_master" do
        self.cloud.security_group 'hadoop_namenode' do
          authorize_port_range 80..80
        end
      end

      role_implication "nfs_server" do
        self.cloud.security_group "nfs_server" do
          authorize_group "nfs_client"
        end
      end

      role_implication "nfs_client" do
        self.cloud.security_group "nfs_client"
      end

      role_implication "ssh" do
        self.cloud.security_group 'ssh' do
          authorize_port_range 22..22
        end
      end

      role_implication "chef_server" do
        self.cloud.security_group "chef_server" do
          authorize_port_range 4000..4000  # chef-server-api
          authorize_port_range 4040..4040  # chef-server-webui
        end
      end

      role_implication("george") do
        self.cloud.security_group(cluster_name+"-george") do
          authorize_port_range  80..80
          authorize_port_range 443..443
        end
      end
    end
  end

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

    def cluster_name
      self.name
    end

    def use other_cluster_name
      ClusterChef.load_cluster(other_cluster_name)
      merge! other_cluster_name
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
        nn = aws_instance_hash[ s.id ] || s.id
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

  class Facet < ClusterChef::ComputeBuilder
    attr_reader :cluster, :facet_name
    has_keys  :instances, :facet_role

    def initialize cluster, fct_name
      super(facet_name)
      @cluster = cluster
      @facet_name = fct_name
      @servers = {}
      chef_attributes :cluster_role       => facet_name # backwards compatibility
      chef_attributes :facet_name         => facet_name

      facet_role      "#{@cluster.name}_#{facet_name}"
    end

    def servers
      @servers.values
    end

    def get_node_name index
      "#{cluster_name}-#{facet_name}-#{index}"
    end
    
    def cluster_name
      cluster.name
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
      chef_attributes :aws => { :access_key => Chef::Config[:knife][:aws_access_key_id], :secret_access_key => Chef::Config[:knife][:aws_secret_access_key],}
      # Generate server definitions if they have not already been created
      resolve_servers!
      self
      
    end

    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
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

    def cluster_group
      return "#{cluster_name}-#{facet_name}"
    end

  end


  class Server < ClusterChef::ComputeBuilder
    attr_reader :cluster, :facet, :facet_index
    attr_accessor :chef_node, :fog_server
    has_keys :chef_node_name, :instances, :facet_name

    def initialize facet, index
      super facet.get_node_name( index )
      @facet_index = index
      @facet = facet
      @cluster = facet.cluster
   
      @settings[:facet_name] = @facet.facet_name
      
      @settings[:chef_node_name] = name
      chef_attributes :node_name => name
      chef_attributes :cluster_role_index => index
      chef_attributes :facet_index => index
    end

    def cluster_name
      cluster.name
    end

    #
    # Resolve:
    #
    def resolve!
      clname = @cluster.name
      facetname = @facet.name
      
      @settings    = @facet.to_hash.merge @settings

      cloud.resolve!          @facet.cloud
      #cloud.keypair           clname unless cloud.keypair
      #cloud.security_group    clname do authorize_group clname end
      #cloud.security_group "#{clname}-#{self.name}"

      @settings[:run_list]        = @facet.run_list + self.run_list
      @settings[:chef_attributes] = @facet.chef_attributes.merge(self.chef_attributes)

      chef_attributes :run_list => run_list
      chef_attributes :aws => { :access_key => Chef::Config[:knife][:aws_access_key_id], :secret_access_key => Chef::Config[:knife][:aws_secret_access_key],}
      chef_attributes :cluster_chef => { 
        :cluster => cluster_name,
        :facet => facet_name,
        :index => facet_index,
      }
      chef_attributes :node_name => chef_node_name

      self
    end

    # FIXME: a lot of AWS logic in here. This probably lives in the facet.cloud
    # but for the one or two things that come from the facet
    def create_server
      # only create a server if it does not already exist
      return nil if fog_server

      fog_server = ClusterChef.connection.servers.create(
        :image_id          => cloud.image_id,
        :flavor_id         => cloud.flavor,
        #
        :groups            => cloud.security_groups.keys,
        :key_name          => cloud.keypair,
        :tags              => cloud.security_groups.keys,
        :user_data         => JSON.pretty_generate(cloud.user_data.merge(:attributes => chef_attributes)),
        # :block_device_mapping => [],
        # :disable_api_termination => disable_api_termination,
        # :instance_initiated_shutdown_behavior => instance_initiated_shutdown_behavior,
        :availability_zone => cloud.availability_zones.first
        )
    end

    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
    end


  end
end
