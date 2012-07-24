module Ironfan
  class Provider
    class Ec2

      class Instance < Ironfan::IaasProvider::Instance
        delegate :_dump, :addresses, :ami_launch_index, :ami_launch_index=,
            :architecture, :architecture=, :availability_zone,
            :availability_zone=, :block_device_mapping, :block_device_mapping=,
            :client_token, :client_token=, :collection, :collection=,
            :connection, :connection=, :console_output, :created_at,
            :created_at=, :destroy, :dns_name, :dns_name=, :flavor, :flavor=,
            :flavor_id, :flavor_id=, :groups, :groups=, :iam_instance_profile,
            :iam_instance_profile=, :iam_instance_profile_arn=,
            :iam_instance_profile_name=, :id, :id=, :identity, :identity=,
            :image_id, :image_id=, :instance_initiated_shutdown_behavior,
            :instance_initiated_shutdown_behavior=, :ip_address, :kernel_id,
            :kernel_id=, :key_name, :key_name=, :key_pair, :key_pair=,
            :monitor=, :monitoring, :monitoring=, :network_interfaces,
            :network_interfaces=, :new_record?, :password, :password=,
            :placement_group, :placement_group=, :platform, :platform=,
            :private_dns_name, :private_dns_name=, :private_ip_address,
            :private_ip_address=, :private_key, :private_key=,
            :private_key_path, :private_key_path=, :product_codes,
            :product_codes=, :public_ip_address, :public_ip_address=,
            :public_key, :public_key=, :public_key_path, :public_key_path=,
            :ramdisk_id, :ramdisk_id=, :ready?, :reason, :reason=, :reboot,
            :reload, :requires, :requires_one, :root_device_name,
            :root_device_name=, :root_device_type, :root_device_type=, :save,
            :scp, :scp_download, :scp_upload, :security_group_ids,
            :security_group_ids=, :setup, :ssh, :ssh_port, :sshable?, :start,
            :state, :state=, :state_reason, :state_reason=, :stop, :subnet_id,
            :subnet_id=, :symbolize_keys, :tags, :tags=, :tenancy, :tenancy=,
            :user_data, :user_data=, :username, :username=, :volumes, :vpc_id,
            :vpc_id=, :wait_for,
          :to => :adaptee

        def name()
          tags["Name"] || tags["name"]
        end

        def created?
          not ['terminated', 'shutting-down'].include? state
        end
        def stopped?
          state == "stopped"
        end

        def display_values(style,values={})
          # style == :minimal
          values["State"] =             state.to_sym
          values["InstanceID"] =        id
          values["Public IP"] =         public_ip_address
          values["Private IP"] =        private_ip_address
          values["Created On"] =        created_at.to_date
          return values if style == :minimal

          # style == :default
          values["Flavor"] =            flavor_id
          values["AZ"] =                availability_zone
          return values if style == :default

          # style == :expanded
          values["Image"] =             image_id
          values["Volumes"] =           volumes.map(&:id).join(', ')
          values["SSH Key"] =           key_name
          values
        end

#         def remove!
#           self.destroy
#           self.owner.delete(self.name)
#         end
      end

      class Instances < Ironfan::Provider::ResourceCollection
        self.item_type =        Instance

        def load!(machines)
          Ironfan::Provider::Ec2.connection.servers.each do |fs|
            next if fs.blank?
            i = Instance.new(:adaptee => fs)
            i.owner = self
            # Already have a instance by this name
            if self.include? i.name
              i.bogus <<                :duplicate_instances
              self[i.name].bogus <<     :duplicate_instances
              self["#{i.name}-dup:#{i.object_id}"] = i
            else
              self << i
            end
          end
        end

        def correlate!(machines)
          # Match each machine to its corresponding instance
          machines.each do |machine|
            next unless self.include? machine.server.fullname
            instance =          self[machine.server.fullname]
            machine.bogus +=    instance.bogus
            instance.users <<   machine.object_id
            machine[:instance] = instance
          end
          # Find instances that haven't matched, but should have,
          #   make sure all bogus instances have a machine to
          #   attach to for display
          self.each do |instance|
            next unless instance.users.empty?
            if instance.name.match("^#{machines.cluster.name}")
              instance.bogus << :unexpected_instance
            end
            next unless instance.bogus?
            fake =              Ironfan::Broker::Machine.new
            fake[:instance] =   instance
            fake.name =         instance.name
            fake.bogus +=       instance.bogus
            instance.users <<   fake.object_id
            machines <<         fake
          end
        end


        #
        # Manipulation
        #

        #def create!(machines)             end

        #def destroy!(machines)            end

        def save!(machines)
          machines.each do |machine|
            next unless machine.instance?
            tags = {
              'cluster' =>      machine.server.cluster_name,
              'facet' =>        machine.server.facet_name,
              'index' =>        machine.server.index,
              'name' =>         machine.name,
              'Name' =>         machine.name
            }
            Ec2.ensure_tags(tags,machine.instance)

            # the EC2 API does not surface disable_api_termination as a value, so we
            # have to set it every time.
            permanent = machine.server.cloud.permanent
            Ironfan.step(machine.name, "setting termination flag #{permanent}", :blue)
            Ironfan.unless_dry_run do
              Ironfan.safely do
                Ec2.connection.modify_instance_attribute( machine.instance.id,
                  {'DisableApiTermination.Value' => machine.permanent?, })
              end
            end
          end
        end
      end

    end
  end
end