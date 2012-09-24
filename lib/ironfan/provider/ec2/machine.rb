module Ironfan
  class Provider
    class Ec2

      class Machine < Ironfan::IaasProvider::Machine
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


        def self.shared?()      false;  end
        def self.multiple?()    false;  end
#        def self.resource_type()        Ironfan::IaasProvider::Machine;   end
        def self.resource_type()        :machine;   end
        def self.expected_ids(computer) [computer.server.fullname];   end

        def name
          return id if tags.empty?
          tags["Name"] || tags["name"] || id
        end

        def public_hostname()           dns_name;      end

        def created?
          not ['terminated', 'shutting-down'].include? state
        end
        def running?
          state == "running"
        end
        def stopped?
          state == "stopped"
        end

        def start
          adaptee.start
          adaptee.wait_for{ state == 'pending' }
        end

        def stop
          adaptee.stop
          adaptee.wait_for{ state == 'stopping' }
        end

        def to_display(style,values={})
          # style == :minimal
          values["State"] =             state.to_sym
          values["MachineID"] =        id
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

        def ssh_key
          keypair = cloud.keypair || computer.server.cluster_name
        end

        def to_s
          "<%-15s %-12s %-25s %-25s %-15s %-15s %-12s %-12s %s:%s>" % [
            self.class.handle, id, created_at, tags['name'], private_ip_address, public_ip_address, flavor_id, availability_zone, key_name, groups.join(',') ]
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Ironfan.substep(cluster.name, "machines")
          Ec2.connection.servers.each do |fs|
            machine = new(:adaptee => fs)
            if recall? machine.name
              raise 'duplicate'
              machine.bogus <<                 :duplicate_machines
              recall(machine.name).bogus <<    :duplicate_machines
              remember machine, :append_id => "duplicate:#{machine.id}"
            elsif machine.created?
              remember machine
            else
              remember machine, :append_id => "terminated:#{machine.id}"
            end
            Chef::Log.debug("Loaded #{machine}")
          end
        end

        # Find active machines that haven't matched, but should have,
        #   make sure all bogus machines have a computer to attach to
        #   for display purposes
        def self.validate_resources!(computers)
          recall.each_value do |machine|
            next unless machine.users.empty? and machine.name
            if machine.name.match("^#{computers.cluster.name}")
              machine.bogus << :unexpected_machine
            end
            next unless machine.bogus?
            fake           = Ironfan::Broker::Computer.new
            fake[:machine] = machine
            fake.name      = machine.name
            machine.users << fake
            computers     << fake
          end
        end

        #
        # Manipulation
        #
        def self.create!(computer)
          Ironfan.todo("CODE SMELL: overly large method: #{caller}")
          return if computer.machine? and computer.machine.created?
          Ironfan.step(computer.name,"creating cloud machine", :green)
          #
          errors = lint(computer)
          if errors.present? then raise ArgumentError, "Failed validation: #{errors.inspect}" ; end
          #
          launch_desc = launch_description(computer)
          Chef::Log.debug(JSON.pretty_generate(launch_desc))

          Ironfan.safely do
            fog_server = Ec2.connection.servers.create(launch_desc)
            machine = Machine.new(:adaptee => fog_server)
            computer.machine = machine
            remember machine, :id => computer.name

            fog_server.wait_for { ready? }
          end

          # tag the computer correctly
          tags = {
            'cluster' =>      computer.server.cluster_name,
            'facet' =>        computer.server.facet_name,
            'index' =>        computer.server.index,
            'name' =>         computer.name,
            'Name' =>         computer.name,
          }
          Ec2.ensure_tags(tags,computer.machine)

          # register the new volumes for later save!, and tag appropriately
          computer.machine.volumes.each do |v|
            Ironfan.todo "CODE SMELL: Machine is too familiar with EbsVolume problems"
            ebs_vol = Ec2::EbsVolume.register v
            drive = computer.drives.values.select do |drive|
              drive.volume.device == ebs_vol.device
            end.first
            drive.disk = ebs_vol

            vol_name = "#{computer.name}-#{drive.volume.name}"
            tags['server'] = computer.name
            tags['name'] = vol_name
            tags['Name'] = vol_name
            tags['mount_point'] = drive.volume.mount_point
            tags['device'] = drive.volume.device
            Ec2.ensure_tags(tags,ebs_vol)
          end
        end

        # @returns [Hash{String, Array}] of 'what you did wrong' => [relevant, info]
        def self.lint(computer)
          cloud = computer.server.cloud(:ec2)
          info  = [computer.name, cloud.inspect]
          errors = {}
          server_errors = computer.server.lint
          errors["Unhappy Server"] = server_errors if server_errors.present?
          errors["No AMI found"] = info if cloud.image_id.blank?
          errors['Missing client']      = info            unless computer.client?
          errors['Missing private_key'] = computer.client unless computer.private_key
          errors
        end

        def self.launch_description(computer)
          cloud = computer.server.cloud(:ec2)
          user_data_hsh =               {
            :chef_server =>             Chef::Config[:chef_server_url],
            # :validation_client_name => Chef::Config[:validation_client_name],
            #
            :node_name =>               computer.name,
            :organization =>            Chef::Config[:organization],
            :cluster_name =>            computer.server.cluster_name,
            :facet_name =>              computer.server.facet_name,
            :facet_index =>             computer.server.index,
            :client_key =>              computer.private_key
          }

          # Fog does not actually create tags when it creates a server;
          #  they and permanence are applied during sync
          description = {
            :image_id             => cloud.image_id,
            :flavor_id            => cloud.flavor,
            :vpc_id               => cloud.vpc,
            :subnet_id            => cloud.subnet,
            :groups               => cloud.security_groups.keys,
            :key_name             => cloud.ssh_key_name(computer),
            :user_data            => JSON.pretty_generate(user_data_hsh),
            :block_device_mapping => block_device_mapping(computer),
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
        def self.block_device_mapping(computer)
          Ironfan.todo "CODE SMELL: Machine is too familiar with EbsVolume problems"
          computer.drives.values.map do |drive|
            next if drive.disk  # Don't create any disc already satisfied
            volume = drive.volume or next
            hsh = { 'DeviceName' => volume.device }
            if volume.attachable == 'ephemeral'
              hsh['VirtualName'] = drive.name
            # if set for creation at launch (and not already created)
            elsif drive.node[:volume_id].blank? && volume.create_at_launch
              if volume.snapshot_id.blank? && volume.size.blank?
                raise "Must specify a size or a snapshot ID for #{volume}"
              end
              hsh['Ebs.SnapshotId'] = volume.snapshot_id if volume.snapshot_id.present?
              hsh['Ebs.VolumeSize'] = volume.size.to_s   if volume.size.present?
              hsh['Ebs.DeleteOnTermination'] = (not volume.keep).to_s
            else next
            end
            hsh
          end.compact
        end

        def self.destroy!(computer)
          return unless computer.machine?
          forget computer.machine.name
          computer.machine.destroy
          computer.machine.reload            # show the node as shutting down
        end

        def self.save!(computer)
          return unless computer.machine?
          # the EC2 API does not surface disable_api_termination as a value, so we
          # have to set it every time.
          permanent = computer.server.cloud(:ec2).permanent
          return unless computer.created?
          Ironfan.step(computer.name, "setting termination flag #{permanent}", :blue)
          Ironfan.unless_dry_run do
            Ironfan.safely do
              Ec2.connection.modify_instance_attribute( computer.machine.id,
                {'DisableApiTermination.Value' => computer.permanent?, })
            end
          end
        end
      end

    end
  end
end
