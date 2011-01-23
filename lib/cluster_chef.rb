
require 'fog'
require 'chef'
require 'chef/knife'

require 'cluster_chef/dsl_object'
require 'cluster_chef/cloud'
require 'cluster_chef/security_group'


module ClusterChef

  class NodeBuilder < ClusterChef::DslObject
    attr_reader :cloud
    @@role_implications ||= {}
    
    def initialize builder_name
      super()
      name         builder_name
      run_list     []
    end

    def cloud cloud_provider=nil, &block
      raise "Only have ec2 so far" if cloud_provider && (cloud_provider != :ec2)
      @cloud ||= ClusterChef::Cloud::Aws.new
      yield @cloud if block
      @cloud
    end

    def chef_attributes hsh={}
      @settings[:chef_attributes] ||= {}
      @settings[:chef_attributes].merge! hsh unless hsh.blank?
      @settings[:chef_attributes]
    end

    def role role_name
      run_list << "role[#{role_name}]"
      @@role_implications[role_name].call(self) if @@role_implications[role_name]
    end
    def recipe name
      run_list << name
    end
    def role_implication name, &block
      @@role_implications[name] = block 
    end
    
    def to_yaml
      to_hash.merge({ :cloud => cloud.to_hash, }).to_yaml
    end
  end

  class Cluster < ClusterChef::NodeBuilder
    def initialize cluster_name
      super(cluster_name)
      @facets = {}
      cloud.keypair         cluster_name
      cloud.security_group  cluster_name
      role               "#{cluster_name}_cluster"
      chef_attributes :cluster_name => cluster_name
      chef_attributes :aws => { :access_key => Chef::Config[:knife][:aws_access_key_id], :secret_access_key => Chef::Config[:knife][:aws_secret_access_key],}
    end

    def facet facet_name, &block
      @facets[facet_name] ||= ClusterChef::Facet.new(self, facet_name)
      yield @facets[facet_name] if block
      @facets[facet_name]
    end
  end

  class Facet < ClusterChef::NodeBuilder
    attr_reader :cluster
    
    def initialize cluster, facet_name
      super(facet_name)
      @cluster = cluster
      cloud.security_group "#{cluster.name}_#{facet_name}"
      role                 "#{cluster.name}_#{facet_name}"
      chef_node_name       "#{cluster.name}-#{facet_name}-0"
      chef_attributes :node_name          => chef_node_name
      chef_attributes :cluster_role       => facet_name
      chef_attributes :facet_name         => facet_name
      chef_attributes :cluster_role_index => 0
    end

    #
    # Resolve: 
    #
    def resolve! builder
      @settings = builder.to_hash.merge @settings
      @settings[:run_list]        = builder.run_list + self.run_list
      @settings[:chef_attributes] = builder.chef_attributes.merge(self.chef_attributes)
      cloud.reverse_merge! builder.cloud
      self
    end
    
    # FIXME: a lot of AWS logic in here. This probably lives in the facet.cloud
    # but for the one or two things that come from the facet
    def create_servers
      cloud.connection.servers.create(
        :image_id          => cloud.image_id,
        :flavor_id         => cloud.flavor,
        # 
        :min_count         => instances,
        :max_count         => instances,
        :groups            => cloud.security_groups.keys,
        :key_name          => cloud.keypair,
        :tags              => cloud.security_groups.keys,
        :user_data         => JSON.pretty_generate(cloud.user_data.merge(:attributes => chef_attributes.merge(:run_list => run_list))),
        # :block_device_mapping => [],
        # :disable_api_termination => disable_api_termination,
        # :instance_initiated_shutdown_behavior => instance_initiated_shutdown_behavior,
        :availability_zone => cloud.availability_zones.first
        )
    end

    def list_servers
      cloud.connection.servers.all
    end    
  end
end

def cluster name, &block
  Chef::Config[:clusters]       ||= {}
  Chef::Config[:clusters][name] = ClusterChef::Cluster.new(name)
  yield Chef::Config[:clusters][name]
end

# # Reads the validation key in directly from a file
# def get_chef_validation_key settings
#   set[:validation_key_file] = '~/.chef/keypairs/mrflip-validator.pem'
#   validation_key_file = File.expand_path(set[:validation_key_file])
#   return unless File.exists?(validation_key_file)
#   set[:userdata][:validation_key] ||= File.read(validation_key_file)
# end
# 
# def cluster_name
#   Settings[:cluster_name]
# end
# 
# def instances n_instances
#   set[:instances] = n_instances
# end
# 

# def security_group name, options={}, &block
#   set[:cloud][:security_groups] << name
# end
# 
# 
# def has_dynamic_volumes
#   set[:run_list] << 'attaches_volumes'
#   set[:run_list] << 'mounts_volumes'
# end
# 
# def override_attributes options
#   set[:override_attributes].merge! options
# end
