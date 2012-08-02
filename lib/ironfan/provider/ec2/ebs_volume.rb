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
        field :dsl_volume,        Ironfan::Dsl::Volume

        def name
          tags["Name"] || tags["name"] || id
        end

        def ephemeral_device?
          false
        end
      end

      class EbsVolumes < Ironfan::Provider::ResourceCollection
        self.item_type =        EbsVolume

        #
        # Discovery
        #
        def load!(machines)
          Ec2.connection.volumes.each do |vol|
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
          Chef::Log.debug("starting ebs_volumes.correlate!")
          machines.select(&:server?).each do |machine|
            machine.server.volumes.each do |volume|
              unless volume.attachable == 'ebs'
                Chef::Log.debug("Ignoring non-EBS volume = #{volume}")
                next
              end

              store =           machine.store(volume.name)
              store.node =      machine.node[:volumes][volume.name].to_hash rescue {}
              if store.node.has_key? :volume_id
                node_volume_id = store.node[:volume_id]
              end
              ebs_name =        "#{machine.server.fullname}-#{volume.name}"

              volume_id =       volume.volume_id
              volume_id ||=     node_volume_id

              # Volumes may match against name derived from the cluster definition,
              #   or volume_id from the cluster definition or node
              case
              when (include? ebs_name)
                ebs =           self[ebs_name]
              when (volume_id and include? volume_id)
                ebs =           self[volume_id]
              else
                log_message =   "Volume not found: name = #{ebs_name}"
                log_message +=  ", volume_id = #{volume_id}"
                Chef::Log.debug(log_message)
                next
              end

              # Make sure all the known volume_ids match
              [ ebs.id, volume.volume_id, node_volume_id ].compact.each do |id|
                id == volume_id or ebs.bogus << :volume_id_mismatch
              end if volume_id

              machine.bogus +=  ebs.bogus
              ebs.users <<      machine.object_id
              store.volume =    volume
              store.disk =      ebs
            end
          end
        end

        #
        # Manipulation
        #

        # # Ironfan currently only creates EbsVolumes via flags on the instance
        # #   launch, so there's no need for this at the moment
        # def create!(machines)         end

        #def destroy!(machines)         end

        def save!(machines)
          machines.each do |machine|
            Ironfan.step(machine.name,"syncing EBS volumes",:blue)
            machine.stores.each do |store|
              # Only worry about machines with ebs volumes
              ebs = store.disk or next
              # Only attach volumes if they aren't already attached
              if ebs.server_id.nil?
                Ironfan.step(machine.name, "  - attaching #{ebs.name}", :blue)
                Ironfan.safely do
                  ebs.device =          store.volume.device
                  ebs.server =          machine.instance.adaptee
                end
              end
              # Record the volume information in chef
              store.node['volume_id'] =  ebs.id
            end
          end
          machines
        end

      end

    end
  end
end