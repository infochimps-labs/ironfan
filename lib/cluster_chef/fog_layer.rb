module ClusterChef
  #
  # ClusterChef::Server methods that handle Fog action
  #
  Server.class_eval do

    def fog_create_server
      step(" creating cloud server", :green)
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
        :user_data         => JSON.pretty_generate(cloud.user_data),
        :block_device_mapping    => block_device_mapping,
        # :disable_api_termination => cloud.permanent,
        # :instance_initiated_shutdown_behavior => instance_initiated_shutdown_behavior,
        :availability_zone => self.default_availability_zone,
        :monitoring => cloud.monitoring,
      }
    end

    #
    # Takes key-value pairs and idempotently sets those tags on the cloud machine
    #
    def fog_create_tags(tags)
      step("  labeling servers")
      tags.each do |key, value|
        next if fog_server.tags[key] == value.to_s
        Chef::Log.debug( "tagging #{key} = #{value} on #{self.fullname}" )
        safely do
          ClusterChef.fog_connection.tags.create({
            :key => key, :value => value.to_s, :resource_id => fog_server.id })
        end
      end
    end

    def fog_address
      address_str = self.cloud.public_ip or return
      ClusterChef.fog_addresses[address_str]
    end

    def attach_volumes
      return unless in_cloud?
      discover_volumes!
      vols = composite_volumes.reject{|vol_name, vol| (not vol.volume_id) || (vol.ephemeral_device?) }
      return if composite_volumes.empty?
      step("  attaching volumes")
      composite_volumes.each do |vol_name, vol|
        next if vol.volume_id.blank? || (vol.attachable != :ebs)
        desc = "#{vol_name} on #{self.fullname} (#{vol.volume_id} @ #{vol.device})"
        if (not vol.in_cloud?) then  Chef::Log.debug("Volume not found: #{desc}") ; next ; end
        if (vol.has_server?)   then check_server_id_pairing(vol.fog_volume, desc) ; next ; end
        step("  - attaching #{desc} -- #{vol.inspect}", :green)
        safely do
          vol.fog_volume.device = vol.device
          vol.fog_volume.server = fog_server
        end
      end
    end

    def associate_public_ip
      address = self.cloud.public_ip
      return unless self.in_cloud? && address
      desc = "elastic ip #{address} for #{self.fullname}"
      if (fog_address && fog_address.server_id) then check_server_id_pairing(fog_address, desc) ; return ; end
      safely do
        step("  assigning #{desc}", :green)
        ClusterChef.fog_connection.associate_address(self.fog_server.id, address)
      end
    end

  end

  class ServerSlice
    def sync_keypairs
      step("ensuring keypairs exist")
      keypairs  = servers.map{|svr| [svr.cluster.cloud.keypair, svr.cloud.keypair] }.flatten.map(&:to_s).reject(&:blank?).uniq
      keypairs  = keypairs - ClusterChef.fog_keypairs.keys
      keypairs.each do |keypair_name|
        keypair_obj = ClusterChef::Ec2Keypair.create!(keypair_name)
        ClusterChef.fog_keypairs[keypair_name] = keypair_obj
      end
    end
  end
end
