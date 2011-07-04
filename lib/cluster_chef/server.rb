module ClusterChef

  #
  # A server is a specific (logical) member of a facet within a cluster.
  #
  # It may have extra attributes if it also exists in the Chef server,
  # or if it exists in the real world (as revealed by Fog)
  #
  class Server < ClusterChef::ComputeBuilder
    attr_reader   :cluster, :facet, :facet_index
    attr_accessor :chef_node, :fog_server

    @@all ||= Mash.new

    def initialize facet, idx
      @cluster     = facet.cluster
      @facet       = facet
      @facet_index = idx
      super(fullname)
      warn("Duplicate server #{[self, facet.name, idx]} vs #{@@all[fullname]}") if @@all[fullname]
      @@all[fullname] = self
    end

    def fullname
      [cluster_name, facet_name, facet_index].join('-')
    end

    def self.get(fullname)
      cluster_name, facet_name, facet_index = fullname.split('-')
      cluster = Cluster.get(cluster_name)
      had_facet = cluster.has_facet?(facet_name)
      facet = cluster.facet(facet_name)
      facet.bogosity true if (! had_facet)
      facet.server(facet_index)
    end

    def self.all
      @@all
    end

    def cluster_name
      cluster.name
    end

    def facet_name
      facet.name
    end

    def security_groups
      cloud.security_groups
    end

    def tag key, value=nil
      if value then @tags[key] = value ; end
      @tags[key]
    end

    def servers
      ClusterChef::ServerGroup.new(cluster, [self])
    end

    def bogus?
      facet.bogus? || (self.facet_index.to_i >= facet.instances)
    end

    def created?
      fog_server
    end

    def to_s
      super[0..-3] + " chef: #{chef_node && chef_node.node_name} fog: #{fog_server && fog_server.id}}>"
    end

    #
    # Resolve:
    #
    def resolve!
      @settings = @facet.to_hash.merge @settings
      cloud.resolve! @facet.cloud

      chef_attributes :node_name => name
      chef_attributes :cluster_role_index => facet_index
      chef_attributes :facet_index => facet_index
      chef_attributes :cluster_name => cluster_name
      chef_attributes :cluster_role => facet_name # backwards compatibility
      chef_attributes :facet_name   => facet_name

      @tags = { "cluster" => cluster_name,
                "facet"   => facet_name,
                "index"   => facet_index }


      @settings[:run_list]        = @facet.run_list + self.run_list
      @settings[:chef_attributes] = @facet.chef_attributes.merge(self.chef_attributes)
      chef_attributes(
        :run_list => run_list,
        :node_name => chef_node_name,
        :cluster_chef => {
          :cluster => cluster_name,
          :facet => facet_name,
          :index => facet_index,
        })
      self
    end

    # FIXME: a lot of AWS logic in here. This probably lives in the facet.cloud
    # but for the one or two things that come from the facet
    def create_server
      # only create a server if it does not already exist
      return nil if fog_server

      fog_description = {
        :image_id          => cloud.image_id,
        :flavor_id         => cloud.flavor,
        #
        :groups            => cloud.security_groups.keys,
        :key_name          => cloud.keypair,
        # Fog does not actually create tags when it creates a server.
        :tags              => {
          :cluster => cluster_name,
          :facet   => facet_name,
          :index   => facet_index, },
        :user_data         => JSON.pretty_generate(cloud.user_data.merge(:attributes => chef_attributes)),
        :block_device_mapping    => volumes.map(&:block_device_mapping),
        # :disable_api_termination => cloud.disable_api_termination,
        # :instance_initiated_shutdown_behavior => instance_initiated_shutdown_behavior,
        :availability_zone => cloud.availability_zones.first,
        :monitoring => cloud.monitoring,
      }
      @fog_server = ClusterChef.connection.servers.create(fog_description)
    end

    def create_tags
      tags = {
        "cluster" => cluster_name,
        "facet"   => facet_name,
        "index"   => facet_index, }
      tags.each_pair do |key,value|
        ClusterChef.connection.tags.create(
          :key         => key,
          :value       => value,
          :resource_id => fog_server.id)
      end
    end

    def attach_volumes
      volumes.each do |vol|
        next unless vol.volume_id
        volume = ClusterChef.connection.volumes.select{|v| v.id == id }[0]
        next unless volume
        volume.device = vol_spec[:device]
        volume.server = fog_server
      end
    end

    def to_hash_with_cloud
      to_hash.merge({ :cloud => cloud.to_hash, })
    end
  end
end
