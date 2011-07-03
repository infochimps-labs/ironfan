module ClusterChef
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

      @tags = { "cluster" => cluster_name,
                "facet"   => facet_name,
                "index"   => facet_index }

      @volumes = []

    end

    def cluster_name
      cluster.name
    end

    def security_groups
      groups = cloud.security_groups
    end

    def tag key,value=nil
      return @tags[key] unless value
      @tags[key] = value
    end

    def servers
      return [self]
    end

    def volume specs
      # specs should be a hash of the following form
      # { :id          =>  "vol-xxxxxxxx",   # the id of the volume to attach
      #   :device      => "/dev/sdq",        # the device to attach to
      # }
      @volumes.push specs
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
      # chef_attributes :aws => {
      #   :access_key => Chef::Config[:knife][:aws_access_key_id],
      #   :secret_access_key => Chef::Config[:knife][:aws_secret_access_key],
      # }
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

      fog_description = {
        :image_id          => cloud.image_id,
        :flavor_id         => cloud.flavor,
        #
        :groups            => cloud.security_groups.keys,
        :key_name          => cloud.keypair,
        # Fog does not actually create tags when it creates a server.
        :tags              =>
          { :cluster => cluster_name,
            :facet =>   facet_name,
            :index =>   facet_index,
          },
        :user_data         => JSON.pretty_generate(cloud.user_data.merge(:attributes => chef_attributes)),
        :block_device_mapping    => cloud.block_device_mapping_array,
        # :disable_api_termination => cloud.disable_api_termination,
        # :instance_initiated_shutdown_behavior => instance_initiated_shutdown_behavior,
        :availability_zone => cloud.availability_zones.first,
        :monitoring => cloud.monitoring,
      }
      @fog_server = ClusterChef.connection.servers.create(fog_description)
    end

    def create_tags
      tags = { "cluster" => cluster_name,
        "facet"   => facet_name,
        "index"   => facet_index, }
      tags.each_pair do |key,value|
        ClusterChef.connection.tags.create(:key => key,
                                           :value => value,
                                           :resource_id => fog_server.id)
      end
    end

    def attach_volumes
      @volumes.each do |vol_spec|
        id = vol_spec[:id]
        next unless id
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
