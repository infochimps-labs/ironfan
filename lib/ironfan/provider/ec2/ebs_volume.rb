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
          tags["Name"] || tags["name"]
        end
      end

      class EbsVolumes < Ironfan::Provider::ResourceCollection
        self.item_type =        EbsVolume
        
        def discover!(cluster)
          Ironfan::Provider::Ec2.connection.volumes.each do |vol|
            next if vol.blank?
            v = EbsVolume.new(:adaptee => vol)
            # Already have a volume by this name
            if self.include? v.name
              v.bogus <<                :duplicate_volumes
              self[v.name].bogus <<     :duplicate_volumes
              self["#{v.name}-dup:#{v.object_id}"] = v
            else
              self << v
            end
          end
        end

        def correlate!(cluster,machines)
          machines.each do |machine|
            server = machine.server
            server.volumes.each do |volume|
              ebs_name =        "#{server.fullname}-#{volume.name}"
              next unless self.include? ebs_name
              ebs =             self[ebs_name]
              machine.bogus +=  ebs.bogus
              ebs.users <<      machine.object_id
              res_name =        "ebs_#{ebs_name}".to_sym
              machine[res_name] = ebs
            end
          end
        end

        def sync!(machines)
          raise 'unimplemented'
        end
      end

    end
  end
end