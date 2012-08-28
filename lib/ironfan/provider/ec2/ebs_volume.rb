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

        def self.shared?()      false;  end
        def self.multiple?()    true;   end
        def self.resource_type()        :ebs_volume;   end
        def self.expected_ids(computer)
          computer.server.volumes.values.map do |volume|
            saved = computer.node[:volumes][volume.name][:volume_id] rescue nil
            ebs_name = "#{computer.server.fullname}-#{volume.name}"
            [ volume.volume_id, saved, ebs_name]
          end.flatten.compact
        end

        def name
          tags["Name"] || tags["name"] || id
        end

        def ephemeral_device?
          false
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Ec2.connection.volumes.each do |vol|
            next if vol.blank?
            ebs = EbsVolume.new(:adaptee => vol)
            # Already have a volume by this name
            if recall? ebs.name
              ebs.bogus <<              :duplicate_volumes
              recall(ebs.name).bogus << :duplicate_volumes
              remember ebs, :append_id => "duplicate:#{ebs.id}"
            else
              remember ebs
            end
          end
        end

        def on_correlate(computer)
          Chef::Log.warn("ebs_volume::on_correlate is incomplete")
        end

#         def self.correlate!(computer)
#           Chef::Log.warn("CODE SMELL: overly large method: #{caller}")
#           return unless computer.server?
#           computer.server.volumes.each do |volume|
#             unless volume.attachable.to_s == 'ebs'
#               Chef::Log.debug("Ignoring non-EBS volume = #{volume}")
#               next
#             end
# 
#             drive =             computer.drive(volume.name)
#             drive.node =        computer.node[:volumes][volume.name].to_hash rescue {}
#             if drive.node.has_key? :volume_id
#               node_volume_id =  drive.node[:volume_id]
#             end
#             ebs_name =          "#{computer.server.fullname}-#{volume.name}"
# 
#             volume_id =         volume.volume_id
#             volume_id ||=       node_volume_id
# 
#             # Volumes may match against name derived from the cluster definition,
#             #   or volume_id from the cluster definition or node
#             case
#             when (recall? ebs_name)
#               ebs =             recall ebs_name
#             when (volume_id and recall? volume_id)
#               ebs =             recall volume_id
#             else
#               log_message =     "Volume not found: name = #{ebs_name}"
#               log_message +=    ", volume_id = #{volume_id}"
#               Chef::Log.debug(log_message)
#               next
#             end
# 
#             # Make sure all the known volume_ids match
#             [ ebs.id, volume.volume_id, node_volume_id ].compact.each do |id|
#               id == volume_id or ebs.bogus << :volume_id_mismatch
#             end if volume_id
# 
#             computer.bogus +=   ebs.bogus
#             ebs.owner =         computer.object_id
#             drive.volume =      volume
#             drive.disk =        ebs
#           end
#         end
        def self.validate_computer!(computer)
          Chef::Log.warn("ebs_volume::validate_computer! is incomplete")
#             # Make sure all the known volume_ids match
#             [ ebs.id, volume.volume_id, node_volume_id ].compact.each do |id|
#               id == volume_id or ebs.bogus << :volume_id_mismatch
#             end if volume_id
        end

        #
        # Manipulation
        #

        def self.save!(computer)
          Ironfan.step(computer.name,"syncing EBS volumes",:blue)
          computer.drives.each do |drive|
            # Only worry about computers with ebs volumes
            ebs = drive.disk or next
            # Only attach volumes if they aren't already attached
            if ebs.server_id.nil?
              Ironfan.step(computer.name, "  - attaching #{ebs.name}", :blue)
              Ironfan.safely do
                ebs.device =          drive.volume.device
                ebs.server =          computer.machine.adaptee
              end
            end
            # Record the volume information in chef
            drive.node['volume_id'] =  ebs.id
          end
        end
      end

    end
  end
end