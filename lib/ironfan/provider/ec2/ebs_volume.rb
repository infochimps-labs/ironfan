module Ironfan
  class Provider
    class Ec2

      class EbsVolume < Ironfan::Provider::Resource
        delegate :_dump, :attached_at, :attached_at=, :attributes,
            :availability_zone, :availability_zone=, :collection, :collection=,
            :connection, :connection=, :created_at, :created_at=,
            :delete_on_termination, :delete_on_termination=, :destroy, :device,
            :device=, :dup_attributes!, :force_detach, :id, :id=, :identity,
            :identity=, :merge_attributes, :missing_attributes, :new_record?,
            :ready?, :reload, :requires, :requires_one, :save, :server,
            :server=, :server_id, :server_id=, :size, :size=, :snapshot,
            :snapshot_id, :snapshot_id=, :snapshots, :state, :state=,
            :symbolize_keys, :tags, :tags=, :wait_for,
          :to => :adaptee

        def name
          tags["Name"] || tags["name"] || id
        end
      end

      class EbsVolumes < Ironfan::Provider::ResourceCollection
        self.item_type =        EbsVolume

        #
        # Discovery
        #
        def load!(machines)
          Ironfan::Provider::Ec2.connection.volumes.each do |vol|
            next if vol.blank?
            ebs = EbsVolume.new(:adaptee => vol)
            # Already have a volume by this name
            if include? ebs.name
              ebs.bogus <<              :duplicate_volumes
              self[ebs.name].bogus <<   :duplicate_volumes
              dup_index =               "#{ebs.name}-dup:#{ebs.object_id}"
              self[dup_index] =         ebs
            else
              self <<                   ebs
            end
          end
        end

        def correlate!(machines)
          machines.each do |machine|
            machine.server.volumes.each do |volume|
              next unless volume.attachable == :ebs

              chef =                    machine.node[:volumes][volume.name]
              chef_volume_id =          chef.volume_id if chef.has_key? :volume_id
              ebs_name =                "#{machine.server.fullname}-#{volume.name}"

              volume_id =               volume.volume_id
              volume_id ||=             chef_volume_id

              # Volumes may match against name derived from the cluster definition,
              #   or volume_id from the cluster definition or node
              case
              when (include? ebs_name)
                ebs =                   self[ebs_name]
              when (volume_id and include? volume_id)
                ebs =                   self[volume_id]
              else
                log_message = "Volume not found: name = #{ebs_name}"
                log_message += ", volume_id = #{volume_id}"
                Chef::Log.debug(log_message)
                next
              end

              # Make sure all the volume_ids match
              [ ebs.id, volume.volume_id, chef_volume_id ].compact.each do |id|
                id == volume_id or ebs.bogus << :volume_id_mismatch
              end

              machine.bogus +=          ebs.bogus
              ebs.users <<              machine.object_id
              res_name =                "ebs_#{ebs_name}".to_sym
              machine[:ebs_volumes] ||= EbsVolumes.new
              machine[:ebs_volumes] <<  ebs
            end
          end
        end

        #
        # Manipulation
        #

        #def create!(machines)             end

        #def destroy!(machines)            end

        #def save!(machines)               end

        # def attach_volumes
        #   return unless in_cloud?
        #   discover_volumes!
        #   return if volumes.empty?
        #   step("  attaching volumes")
        #   volumes.each_pair do |vol_name, vol|
        #     next if vol.volume_id.blank? || (vol.attachable != :ebs)
        #     if (not vol.in_cloud?) then  Chef::Log.debug("Volume not found: #{vol.desc}") ; next ; end
        #     if (vol.has_server?)   then check_server_id_pairing(vol.fog_volume, vol.desc) ; next ; end
        #     step("  - attaching #{vol.desc} -- #{vol.inspect}", :blue)
        #     safely do
        #       vol.fog_volume.device = vol.device
        #       vol.fog_volume.server = fog_server
        #     end
        #   end
        # end

        # def sync!(machines)
        #   discover!
        #   correlate!(nil,machines)
        #   machines.select{|m| m[:ebs_volumes]}.each do |machine|
        #     Ironfan.step(machine.name,"attaching EBS volumes",:blue)
        #     machine[:ebs_volumes].each do |volume|
        #
        #     end
        #   end
        #   raise 'unfinished'
        # end
      end

    end
  end
end