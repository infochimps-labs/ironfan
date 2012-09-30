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

        def to_s
          "<%-15s %-12s %-25s %-32s %-10s %-12s %-15s %-5s %s:%s>" % [
            self.class.handle, id, created_at, tags['name'], state, device, tags['mount_point'], size, server_id, attached_at ]
        end

        def self.shared?()      true;   end
        def self.multiple?()    true;   end
        def self.resource_type()        :ebs_volume;   end
        def self.expected_ids(computer)
          computer.server.volumes.values.map do |volume|
            saved = computer.node[:volumes][volume.name][:volume_id] rescue nil
            ebs_name = "#{computer.server.fullname}-#{volume.name}"
            [ volume.volume_id, saved, ebs_name ]
          end.flatten.compact
        end

        def name
          tags["Name"] || tags["name"] || id
        end

        def drivename
          return id unless tags.key? "Name"
          tags["Name"].split('-').pop
        end

        def ephemeral_device?
          false
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Ironfan.substep(cluster ? cluster.name : 'all', "volumes")
          Ec2.connection.volumes.each do |vol|
            next if vol.blank?
            # FIXME: need to skip 'deleting' volumes
            ebs = EbsVolume.new(:adaptee => vol)
            # Already have a volume by this name
            if recall? ebs.name
              ebs.bogus <<              :duplicate_volumes
              recall(ebs.name).bogus << :duplicate_volumes
              remember ebs, :append_id => "duplicate:#{ebs.id}"
            else
              remember ebs
            end
            Chef::Log.debug("Loaded #{ebs}")
          end
        end

        def on_correlate(computer)
          drive = computer.drive(drivename)
          drive.disk = self
          drive.node = computer.node[:volumes][drivename].to_hash rescue {}
          drive
        end

        def self.validate_computer!(computer)
          computer.drives.each do |drive|
            next unless drive.disk.class == EbsVolume
            [ (drive.node['volume_id'] rescue nil),
              (drive.volume.volume_id  rescue nil)
            ].compact.each do |id|
              Chef::Log.debug "checking #{id} against ebs_volume id #{drive.disk.id}"
              id == drive.disk.id or drive.disk.bogus << :volume_id_mismatch
            end
          end
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
          end
        end
      end

    end
  end
end
