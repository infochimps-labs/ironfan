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
      @settings[:chef_attributes].merge! hsh unless hsh.blank?
      @settings[:chef_attributes]
    end

    # Adds the given role to the run list, and invokes any role_implications it
    # implies (for instance, the 'ssh' role on an ec2 machine requires port 22
    # be explicity opened.)
    #
    def role role_name
      run_list << "role[#{role_name}]"
      @@role_implications[role_name].call(self) if @@role_implications[role_name]
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
  end

  #
  # A cluster has many facets. Any setting applied here is merged with the facet
  # at resolve time; if the facet explicitly sets any attributes they will win out.
  #
  class Cluster < ClusterChef::ComputeBuilder
    def initialize cluster_name
      super(cluster_name)
      @facets = {}
      role           "#{cluster_name}_cluster"
      chef_attributes  :cluster_name => cluster_name
      chef_attributes  :aws => { :access_key => Chef::Config[:knife][:aws_access_key_id], :secret_access_key => Chef::Config[:knife][:aws_secret_access_key],}
    end

    def facet facet_name, &block
      @facets[facet_name] ||= ClusterChef::Facet.new(self, facet_name)
      @facets[facet_name].instance_eval(&block) if block
      @facets[facet_name]
    end
  end

  class Facet < ClusterChef::ComputeBuilder
    attr_reader :cluster
    has_keys :chef_node_name, :instances, :facet_index

    def initialize cluster, facet_name
      super(facet_name)
      @cluster = cluster
      role           "#{cluster.name}_#{facet_name}"
      chef_attributes :cluster_role       => facet_name # backwards compatibility
      chef_attributes :facet_name         => facet_name
      unless facet_index.blank?
        chef_node_name "#{cluster.name}-#{facet_name}-#{facet_index}"
        chef_attributes :node_name          => chef_node_name
        chef_attributes :cluster_role_index => facet_index # backwards compatibility
        chef_attributes :facet_index        => facet_index
      end
    end

    #
    # Resolve:
    #
    def resolve!
      @settings = @cluster.to_hash.merge @settings
      @settings[:run_list]        = @cluster.run_list + self.run_list
      @settings[:chef_attributes] = @cluster.chef_attributes.merge(self.chef_attributes)
      cluster_name = @cluster.name
      cloud.resolve!          @cluster.cloud
      cloud.keypair           cluster_name if cloud.keypair.blank?
      cloud.security_group    cluster_name do
        authorize_group cluster_name
      end
      cloud.security_group "#{@cluster.name}-#{self.name}"
      chef_attributes :run_list => run_list
      self
    end

    # FIXME: a lot of AWS logic in here. This probably lives in the facet.cloud
    # but for the one or two things that come from the facet
    def create_server
      ClusterChef.connection.servers.create(
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
