module Ironfan
  class Provider
    class OpenStack

      class Machine < Ironfan::IaasProvider::Machine
        delegate :_dump, :addresses, :ami_launch_index, :ami_launch_index=,
            :architecture, :architecture=, :availability_zone,
            :availability_zone=, :block_device_mapping, :block_device_mapping=,
            :client_token, :client_token=, :collection, :collection=,
            :connection, :connection=, :console_output, 
            :destroy, 
            :ebs_optimized, :flavor, :flavor=,
            :iam_instance_profile,
            :iam_instance_profile=, :iam_instance_profile_arn=,
            :iam_instance_profile_name=, :id, :id=, :identity, :identity=,
            :image, :image=, :instance_initiated_shutdown_behavior,
            :instance_initiated_shutdown_behavior=, :ip_address, :kernel_id,
            :kernel_id=, :key_name, :key_name=, :key_pair, :key_pair=,
            :monitor=, :monitoring, :monitoring=, :network_interfaces,
            :network_interfaces=, :new_record?, :password, :password=,
            :placement_group, :placement_group=, :platform, :platform=,
            :private_key, :private_key=,
            :private_key_path, :private_key_path=, :product_codes,
            :product_codes=, 
            :public_key, :public_key=, :public_key_path, :public_key_path=,
            :ramdisk_id, :ramdisk_id=, :ready?, :reason, :reason=, :reboot,
            :reload, :requires, :requires_one, :root_device_name,
            :root_device_name=, :root_device_type, :root_device_type=, :save,
            :scp, :scp_download, :scp_upload, :security_group_ids,
            :security_group_ids=, :setup, :ssh, :ssh_port, :sshable?, :start,
            :state, :state=, :state_reason, :state_reason=, :stop, :subnet_id,
            :subnet_id=, :symbolize_keys, :tenancy, :tenancy=,
            :user_data, :user_data=, :username, :username=, :volumes, 
            :wait_for, :name, :name=, 
            :metadata, :metadata=,
          :to => :adaptee

        def self.shared?()      false;  end
        def self.multiple?()    false;  end
#        def self.resource_type()        Ironfan::IaasProvider::Machine;   end
        def self.resource_type()        :machine;   end
        def self.expected_ids(computer) [computer.server.full_name];   end

        def tags
          t = metadata.to_hash.update({"Name" => @adaptee.name})
          return t.keys.inject({}) {|h,k| h[k]=t[k]; h[k.to_sym]=t[k]; h}
        end

        def vpc_id
          return nil
        end

        def created_at
          return @adaptee.created
        end

        def flavor_id
          # sometimes flavor comes back empty - especially right after the machine has been launched
          return flavor && flavor["id"]
        end

        def flavor_name
          fl = OpenStack.flavor_id_hash[ flavor_id ]
          fl && fl.name 
        end

        def image_id
          return image[:id]
        end

        def groups           ; Array(@adaptee.security_groups)   ;   end

        def public_hostname    ; private_ip_address ; end
        def public_ip_address  ; private_ip_address ; end
        def dns_name           ; private_ip_address ; end

        def keypair          ; key_pair ; end

        def created?
          not ['terminated', 'shutting-down'].include? state
        end
        def pending?
          state == "BUILD"
        end
        def running?
          state == "ACTIVE"
        end
        def stopping?
          state == "stopping"
        end
        def stopped?
          state == "SHUTOFF"
        end

        def start
          machine = self
          adaptee.start
          adaptee.wait_for{ machine.pending? or machine.running? }
        end

        def stop
          machine = self
          adaptee.stop
          adaptee.wait_for{ machine.stopping? or machine.stopped? }
        end

        def perform_after_launch_tasks?
          true
        end

        def to_display(style,values={})
          # style == :minimal
          values["State"] =             (state || "unknown").to_sym
          values["MachineID"] =         id
          values["Public IP"] =         private_ip_address
          values["Private IP"] =        private_ip_address
          values["Created On"] =        created_at.to_date
          return values if style == :minimal

          # style == :default
          values["Flavor"] =            flavor_name
          values["AZ"] =                availability_zone
          return values if style == :default

          # style == :expanded
          values["Image"] =             image_id
          #values["Volumes"] =           volumes.map(&:id).join(', ')
          values["SSH Key"] =           key_name
          values
        end

        def ssh_key
          keypair = cloud.keypair || computer.server.cluster_name
        end

        def private_ip_address
          adaptee.private_ip_address rescue nil
        end

        def public_ip_address
          adaptee.public_ip_address rescue nil
        end

        def to_s
          "<%-15s %-12s %-25s %-25s %-15s %-15s %-12s %-12s %s:%s>" % [
            self.class.handle, id, created_at, name, private_ip_address, public_ip_address, flavor_name, availability_zone, key_name, groups.join(',') ]
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          OpenStack.connection.servers.each do |fs|
            machine = new(:adaptee => fs)
            if (not machine.created?)
              next unless Ironfan.chef_config[:include_terminated]
              remember machine, :append_id => "terminated:#{machine.id}"
            elsif recall? machine.name
              machine.bogus <<                 :duplicate_machines
              recall(machine.name).bogus <<    :duplicate_machines
              remember machine, :append_id => "duplicate:#{machine.id}"
            else # never seen it
              remember machine
            end
          end
        end

        def receive_adaptee(obj)
          obj = OpenStack.connection.servers.new(obj) if obj.is_a?(Hash)
          super
        end

        # Find active machines that haven't matched, but should have,
        #   make sure all bogus machines have a computer to attach to
        #   for display purposes
        def self.validate_resources!(computers)
          recall.each_value do |machine|
            next unless machine.users.empty? and machine.name
            if machine.name.match("^#{computers.cluster.name}-")
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

          # tag the computer correctly
          tags = {
            'cluster' =>      computer.server.cluster_name,
            'facet' =>        computer.server.facet_name,
            'index' =>        computer.server.index.to_s,
            'name' =>         computer.name,
            'creator' =>      Chef::Config.username
          }

          Ironfan.safely do
            fog_server = OpenStack.connection.servers.create(launch_desc)
            machine = Machine.new(:adaptee => fog_server)
            computer.machine = machine
            remember machine, :id => computer.name

            Ironfan.step(fog_server.id,"waiting for machine to be ready", :gray)
            Ironfan.tell_you_thrice     :name           => fog_server.id,
                                        :problem        => "server unavailable",
                                        :error_class    => Fog::Errors::Error do
              fog_server.wait_for { state == "ACTIVE" }
            end
          end

          
          computer.machine.metadata.set(tags)

          #OpenStack.ensure_tags(tags, computer.machine)

          # no volumes at the momnt

          # register the new volumes for later save!, and tag appropriately
          #computer.machine.volumes.each do |v|
          #  Ironfan.todo "CODE SMELL: Machine is too familiar with EbsVolume problems"
          #  ebs_vol = OpenStack::EbsVolume.register v
          #  drive = computer.drives.values.select do |drive|
          #    drive.volume.device == ebs_vol.device
          #  end.first
          #  drive.disk = ebs_vol
          # 
          #  vol_name = "#{computer.name}-#{drive.volume.name}"
          #  tags['server'] = computer.name
          #  tags['name'] = vol_name
          #  tags['Name'] = vol_name
          #  tags['mount_point'] = drive.volume.mount_point
          #  tags['device'] = drive.volume.device
          #  OpenStack.ensure_tags(tags,ebs_vol)
          #end
        end

        # @returns [Hash{String, Array}] of 'what you did wrong' => [relevant, info]
        def self.lint(computer)
          cloud = computer.server.cloud(:openstack)
          info  = [computer.name, cloud.inspect]
          errors = {}
          server_errors = computer.server.lint
          errors["Unhappy Server"]      = server_errors   if server_errors.present?
          errors["No AMI found"]        = info            if cloud.image_id.blank?
          errors['Missing client']      = info            unless computer.client?
          errors['Missing private_key'] = computer.client unless computer.private_key
          #
          #all_asserted_regions = [OpenStack.connection.region, cloud.region, Chef::Config[:knife][:region], Ironfan.chef_config[:region]].compact.uniq
          #errors["mismatched region"] = all_asserted_regions unless all_asserted_regions.count == 1
          #
          errors
        end

        def self.launch_description(computer)
          cloud = computer.server.cloud(:openstack)
          user_data_hsh =               {
            :chef_server =>             Chef::Config[:chef_server_url],
            :node_name =>               computer.name,
            :organization =>            Chef::Config[:organization],
            :cluster_name =>            computer.server.cluster_name,
            :facet_name =>              computer.server.facet_name,
            :facet_index =>             computer.server.index,
            :client_key =>              computer.private_key
          }

          # main machine info
          # note that Fog does not actually create tags when it creates a
          #  server; they and permanence are applied during sync
          description = {
            :image_ref             => cloud.image_id,
            :flavor_ref            => OpenStack.flavor_hash[cloud.flavor].id,
            #:vpc_id               => cloud.vpc,
            #:subnet_id            => cloud.subnet,
            :key_name             => cloud.ssh_key_name(computer),
            :user_data            => JSON.pretty_generate(user_data_hsh),
            #:block_device_mapping => block_device_mapping(computer),
            :availability_zone    => cloud.default_availability_zone,
            #:monitoring           => cloud.monitoring,
            :name                 => computer.name,
          }

          # VPC security_groups can only be addressed by id (not name)
          description[:security_group_ids] = cloud.security_groups.keys.map do |g|
            g
          end

          #description[:iam_server_certificates] = cloud.iam_server_certificates.values.map do |cert|
          #  IamServerCertificate.recall(IamServerCertificate.full_name(computer, cert))
          #end.compact.map(&:name)

          #description[:elastic_load_balancers] = cloud.elastic_load_balancers.values.map do |elb|
          #  ElasticLoadBalancer.recall(ElasticLoadBalancer.full_name(computer, elb))
          #end.compact.map(&:name)

          #if cloud.flavor_info[:placement_groupable]
          #  ui.warn "1.3.1 and earlier versions of Fog don't correctly support placement groups, so your nodes will land willy-nilly. We're working on a fix"
          #  description[:placement] = { 'groupName' => cloud.placement_group.to_s }
          #end
          #if cloud.flavor_info[:ebs_optimizable]
          #  description[:ebs_optimized] = cloud.ebs_optimized
          #end
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
          permanent = computer.server.cloud(:openstack).permanent
          return unless computer.created?
          #Ironfan.step(computer.name, "setting termination flag #{permanent}", :blue)
          #Ironfan.unless_dry_run do
          #  Ironfan.safely do
          #    OpenStack.connection.modify_instance_attribute( computer.machine.id,
          #      {'DisableApiTermination.Value' => computer.permanent?, })
          #  end
          #end
        end
      end

    end
  end
end
