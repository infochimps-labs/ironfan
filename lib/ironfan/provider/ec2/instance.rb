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

        def name
          return id if tags.empty?
          tags["Name"] || tags["name"] || id
        end

        def public_hostname()   public_ip_address;      end

        def created?
          not ['terminated', 'shutting-down'].include? state
        end
        def running?
          state == "running"
        end
        def stopped?
          state == "stopped"
        end

        def to_display(style,values={})
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
      end

      class Instances < Ironfan::Provider::ResourceCollection
        self.item_type =        Instance

        def load!(machines)
          Ec2.connection.servers.each do |fs|
            next if fs.blank?
            i = Instance.new(:adaptee => fs)
            i.owner = self
            # Already have a running instance by this name
            if self.include? i.name
              i.bogus <<                :duplicate_instances
              self[i.name].bogus <<     :duplicate_instances
              self["#{i.name}-dup:#{i.id}"] = i
            elsif i.created?
              self << i
            else
              self["#{i.name}-term:#{i.id}"] = i
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
          # Find active instances that haven't matched, but should have,
          #   make sure all bogus instances have a machine to attach to
          #   for display purposes
          self.each do |instance|
            next unless instance.users.empty? and instance.name
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
        def create!(machines)
          machines.each do |machine|
            next if machine.instance? and machine.instance.created?
            Ironfan.step(machine.name,"creating cloud server", :green)
            # lint_fog
            launch_desc = fog_launch_description(machine)
            Chef::Log.debug(JSON.pretty_generate(launch_desc))

            Ironfan.safely do
              fog_server = Ec2.connection.servers.create(launch_desc)
              instance = Instance.new(:adaptee => fog_server)
              machine.instance = instance
              self[machine.name] = instance

              fog_server.wait_for { ready? }
            end

            # tag the machine correctly
            tags = {
              'cluster' =>      machine.server.cluster_name,
              'facet' =>        machine.server.facet_name,
              'index' =>        machine.server.index,
              'name' =>         machine.name,
              'Name' =>         machine.name,
            }
            Ec2.ensure_tags(tags,machine.instance)

            # register the new volumes for later save!, and tag appropriately
            machine.instance.volumes.each do |v|
              ebs_vol = Ironfan.broker.provider(:ec2).ebs_volumes.register!(v)
              store = machine.stores.values.select do |store|
                store.volume.device == ebs_vol.device
              end.first
              store.disk = ebs_vol

              vol_name = "#{machine.name}-#{store.volume.name}"
              tags['name'] = vol_name
              tags['Name'] = vol_name
              Ec2.ensure_tags(tags,ebs_vol)
            end
          end
        end
        def fog_launch_description(machine)
          cloud =                       machine.server.cloud(:ec2)
          user_data_hsh =               {
            :chef_server =>             Chef::Config[:chef_server_url],
            #:validation_client_name =>  Chef::Config[:validation_client_name],
            #
            :node_name =>               machine.name,
            :organization =>            Chef::Config[:organization],
            :cluster_name =>            machine.server.cluster_name,
            :facet_name =>              machine.server.facet_name,
            :facet_index =>             machine.server.index,
            :client_key =>              machine[:client].private_key
          }

          ## This snippet is saved for if/when we ever go back to instances
          ##   creating nodes; currently, the client key must be known locally
          # if client_key then user_data_hsh[:client_key] = client_key
          # else               user_data_hsh[:validation_key] = cloud.validation_key ; end

          # Fog does not actually create tags when it creates a server; 
          #  they and permanence are applied during sync
          keypair = cloud.keypair || machine.server.cluster_name
          description = {
            :image_id             => cloud.image_id,
            :flavor_id            => cloud.flavor,
            :vpc_id               => cloud.vpc,
            :subnet_id            => cloud.subnet,
            :groups               => cloud.security_groups.keys,
            :key_name             => keypair.to_s,
            :user_data            => JSON.pretty_generate(user_data_hsh),
            :block_device_mapping => block_device_mapping(machine),
            :availability_zone    => cloud.default_availability_zone,
            :monitoring           => cloud.monitoring,
          }

          if cloud.flavor_info[:placement_groupable]
            ui.warn "1.3.1 and earlier versions of Fog don't correctly support placement groups, so your nodes will land willy-nilly. We're working on a fix"
            description[:placement] = { 'groupName' => cloud.placement_group.to_s }
          end
          description
        end
        # An array of hashes with dorky-looking keys, just like Fog wants it.
        def block_device_mapping(machine)
          machine.stores.values.map do |store|
            next if store.disk  # Don't create any disc already satisfied
            volume = store.volume or next
            hsh = { 'DeviceName' => volume.device }
            if volume.attachable == 'ephemeral'
              hsh['VirtualName'] = volume.volume_id
            # if set for creation at launch (and not already created)
            elsif store.node[:volume_id].blank? && volume.create_at_launch
              if volume.snapshot_id.blank? && volume.size.blank?
                raise "Must specify a size or a snapshot ID for #{volume}"
              end
              hsh['Ebs.SnapshotId'] = volume.snapshot_id if volume.snapshot_id.present?
              hsh['Ebs.VolumeSize'] = volume.size.to_s   if volume.size.present?
              hsh['Ebs.DeleteOnTermination'] = (not volume.keep).to_s
            else
              next
            end
            hsh
          end.compact
        end

        def destroy!(machines)
          machines.each do |machine|
            next unless machine.instance?
            @clxn.delete(machine.instance.name)
            machine.instance.destroy
            # show the node as shutting down
            machine.instance.reload
            # machine.delete(:instance)
          end
        end

        def save!(machines)
          machines.each do |machine|
            next unless machine.instance?
            # the EC2 API does not surface disable_api_termination as a value, so we
            # have to set it every time.
            permanent = machine.server.cloud(:ec2).permanent
            next unless machine.created?
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

