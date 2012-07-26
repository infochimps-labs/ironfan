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
          Chef::Log.debug("starting ebs_volumes.correlate!")
          machines.each do |machine|
            machine.server.volumes.each do |volume|
              unless volume.attachable == 'ebs'
                Chef::Log.debug("Ignoring non-EBS volume = #{volume}")
                next
              end

              chef =                    machine.node[:volumes][volume.name] rescue nil
              chef_volume_id =          chef.volume_id if (chef and chef.has_key? :volume_id)
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

              # Make sure all the known volume_ids match
              [ ebs.id, volume.volume_id, chef_volume_id ].compact.each do |id|
                id == volume_id or ebs.bogus << :volume_id_mismatch
              end

              machine.bogus +=          ebs.bogus
              ebs.users <<              machine.object_id
              ebs.dsl_volume =          volume
              res_name =                "ebs_#{ebs_name}".to_sym
              machine[:ebs_volumes] ||= EbsVolumes.new
              machine[:ebs_volumes] <<  ebs
            end
          end
        end

        #
        # Manipulation
        #

        def create!(machines)
          # determine create-able Dsl::Volumes
          dsl_vols = machines.map do |m|
            m.server.volumes.values.select do |v|
              v.attachable == 'ebs' and v.create_at_launch
            end
          end.flatten.compact
          # remove those already created
          ebs_vols = machines.map {|m| m[:ebs_volumes].values }.flatten.compact
          ebs_vols.each {|ebs_vol| dsl_vols.delete(ebs_vol.dsl_volume) }

          dsl_vols.each do |dsl_vol|
            pp dsl_vol
          end
          raise 'incomplete'
        end

        #def destroy!(machines)            end

        def save!(machines)
          ebs_machines = machines.select {|m| m[:ebs_volumes] and m.running? }
          ebs_machines.each do |machine|
            # Only attach volumes if they aren't already attached
            ebs_vols = machine[:ebs_volumes].values.select do |ebs|
              ebs.server_id != machine.instance.id
            end
            next if ebs_vols.empty?     # nothing needs attaching
            Ironfan.step(machine.name,"attaching EBS volumes",:blue)
            ebs_vols.each do |ebs|
              Ironfan.step(machine.name, "  - attaching #{ebs.name}", :blue)
              Ironfan.safely do
                ebs.device =            ebs.dsl_volume.device
                ebs.server =            machine.instance.adaptee
              end
            end
          end
          machines
        end

      end

    end
  end
end