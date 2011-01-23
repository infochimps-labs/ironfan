
require 'cluster_chef/rhash'
require 'cluster_chef/dsl_object'
require 'cluster_chef/cloud'

require 'chef'
require 'chef/knife'


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
    
    def to_hash
      super.merge({ :cloud => cloud.to_hash, })
    end

    def role_implication name, &block
      @@role_implications[name] = block 
    end

  end

  class Cluster < ClusterChef::NodeBuilder
    def initialize cluster_name
      super(cluster_name)
      @facets = {}
      cloud.keypair   name
      role      "#{name}_cluster"
    end

    def facet facet_name, &block
      @facets[facet_name] = ClusterChef::Facet.new(self, facet_name) unless @facets.include?(facet_name)
      yield @facets[facet_name] if block
      @facets[facet_name]
    end
    
    # def to_hash
    #   super.merge({ :my_facets => @facets.inject({}){|h,(k,v)| h[k] = v.to_hash ; h } })
    # end
  end

  class Facet < ClusterChef::NodeBuilder
    attr_reader :cluster
    
    def initialize cluster, facet_name
      @cluster = cluster
      super(facet_name)
      role "#{cluster.name}_#{facet_name}"
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
