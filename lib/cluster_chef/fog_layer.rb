module ClusterChef
  #
  # ClusterChef::Server methods that handle Fog action
  #
  Server.class_eval do

    def fog_create_server
      fog_description = fog_description_for_launch
      @fog_server = ClusterChef.fog_connection.servers.create(fog_description)
    end

    def fog_description_for_launch
      {
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
        :block_device_mapping    => block_device_mapping,
        # :disable_api_termination => cloud.disable_api_termination,
        # :instance_initiated_shutdown_behavior => instance_initiated_shutdown_behavior,
        :availability_zone => self.default_availability_zone,
        :monitoring => cloud.monitoring,
      }
    end

    #
    # Takes key-value pairs and idempotently sets those tags on the cloud machine
    #
    def fog_create_tags(tags)
      tags.each do |key, value|
        next if fog_server.tags[key] == value.to_s
        Chef::Log.debug( "Tagging #{key} = #{value} on #{self.fullname}" )
        safely do
          ClusterChef.fog_connection.tags.create({
            :key => key, :value => value.to_s, :resource_id => fog_server.id })
        end
      end
    end

    def fog_address
      address = self.cloud.elastic_ip or return
      ClusterChef.fog_addresses[address]
    end

    def associate_elastic_ip
      address = self.cloud.elastic_ip
      # ap [address, self, fog_address]
      return unless self.in_cloud? && address
      desc = "elastic ip #{address} for #{self.fullname}"
      if (fog_address && fog_address.server_id) then check_server_id_pairing(fog_address, desc) ; return ; end
      Chef::Log.debug("Address: pairing #{desc}")
      safely do
        ClusterChef.fog_connection.associate_address(self.fog_server.id, address)
      end
    end


  end
end
