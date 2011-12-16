module ClusterChef
  #
  # ClusterChef::Server methods that handle Fog action
  #
  Server.class_eval do

    def fog_create_server
      step(" creating cloud server", :green)
      fog_description = fog_description_for_launch
      Chef::Log.debug(JSON.pretty_generate(fog_description))
      safely do
        @fog_server = ClusterChef.fog_connection.servers.create(fog_description)
      end
    end

    def fog_description_for_launch
      {
        :image_id          => cloud.image_id,
        :flavor_id         => cloud.flavor,
        #
        :groups            => cloud.security_groups.keys,
        :key_name          => cloud.keypair.to_s,
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
    def fog_create_tags(fog_obj, desc, tags)
      tags_to_create = tags.reject{|key, val| fog_obj.tags[key] == val.to_s }
      return if tags_to_create.empty?
      step("  tagging #{desc} with #{tags_to_create.inspect}", :green)
      tags_to_create.each do |key, value|
        Chef::Log.debug( "tagging #{desc} with #{key} = #{value}" )
        safely do
          ClusterChef.fog_connection.tags.create({
            :key => key, :value => value.to_s, :resource_id => fog_obj.id })
        end
      end
    end

    def fog_address
      address_str = self.cloud.public_ip or return
      ClusterChef.fog_addresses[address_str]
    end

    def discover_volumes!
      composite_volumes.each do |vol_name, vol|
        my_vol = volumes[vol_name]
        next if my_vol.fog_volume
        my_vol.fog_volume = ClusterChef.fog_volumes.find do |fv|
          ( # matches the explicit volume id
            (vol.volume_id && (fv.id == vol.volume_id)    ) ||
            # OR this server's machine exists, and this volume is attached to
            # it, and in the right place
            ( fog_server && fv.server_id && vol.device  &&
              (fv.server_id   == fog_server.id)         &&
              (fv.device.to_s == vol.device.to_s)         ) ||
            # OR this volume is tagged as belonging to this machine
            ( fv.tags.present?                         &&
              (fv.tags['server'] == self.fullname)     &&
              (fv.tags['device'] == vol.device.to_s) )
            )
        end
        next unless my_vol.fog_volume
        my_vol.volume_id(my_vol.fog_volume.id)                        unless my_vol.volume_id.present?
        my_vol.availability_zone(my_vol.fog_volume.availability_zone) unless my_vol.availability_zone.present?
        check_server_id_pairing(my_vol.fog_volume, my_vol.desc)
      end
    end

    def attach_volumes
      return unless in_cloud?
      discover_volumes!
      return if composite_volumes.empty?
      step("  attaching volumes")
      composite_volumes.each do |vol_name, vol|
        next if vol.volume_id.blank? || (vol.attachable != :ebs)
        if (not vol.in_cloud?) then  Chef::Log.debug("Volume not found: #{vol.desc}") ; next ; end
        if (vol.has_server?)   then check_server_id_pairing(vol.fog_volume, vol.desc) ; next ; end
        step("  - attaching #{vol.desc} -- #{vol.inspect}", :blue)
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
        step("  assigning #{desc}", :blue)
        ClusterChef.fog_connection.associate_address(self.fog_server.id, address)
      end
    end

    def check_server_id_pairing thing, desc
      return unless thing && thing.server_id && self.in_cloud?
      type_of_thing = thing.class.to_s.gsub(/.*::/,"")
      if thing.server_id != self.fog_server.id
        ui.warn "#{type_of_thing} mismatch: #{desc} is on #{thing.server_id} not #{self.fog_server.id}: #{thing.inspect.gsub(/\s+/m,' ')}"
        false
      else
        Chef::Log.debug("#{type_of_thing} paired: #{desc}")
        true
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
