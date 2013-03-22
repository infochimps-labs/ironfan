module Ironfan
  class Provider
    class Vsphere

      class Machine < Ironfan::IaasProvider::Machine
        delegate :config, :connection, :connection=, :disks, :Destroy_Task, :guest, :PowerOffVM_Task, 
          :PowerOnVM_Task, :powerState, :ReconfigVM_Task, :runtime, 
          :to => :adaptee

        def self.shared?()      false;  end
        def self.multiple?()    false;  end
        def self.resource_type()        :machine;   end
        def self.expected_ids(computer) [computer.server.full_name];   end 
        
        def name
           return adaptee.config.name
        end

        def keypair
        end

        def vpc_id
          return true
        end

        def dns_name
          host = adaptee.guest.hostName 
          domain = adaptee.guest.domainName
          return host unless domain
          return "%s.%s" %[host, domain]
        end

        def public_ip_address
          # FIXME
          return adaptee.guest.ipAddress
        end

        def private_ip_address
          return adaptee.guest.ipAddress
        end
 
        def public_hostname
          # FIXME
          return nil
        end

        def destroy
          adaptee.PowerOffVM_Task.wait_for_completion unless adaptee.runtime.powerState == "poweredOff"
          adaptee.Destroy_Task.wait_for_completion
          state = "destroyed"
        end

        def created?
          ["poweredOn", "poweredOff"].include? adaptee.runtime.powerState
        end

        def wait_for
          return true
        end

        def running?
          adaptee.runtime.powerState == "poweredOn"
          state = "poweredOn"
        end

        def stopped?
          adaptee.runtime.powerState == "poweredOff"
          state = "poweredOff"
        end

        def start
          adaptee.PowerOnVM_Task.wait_for_completion
        end

        def stop
          # TODO: Gracefully shutdown guest using adatee.ShutdownGuest ? 
          # There is no "wait_for_completion" with this however...
          adaptee.PowerOffVM_Task.wait_for_completion
        end

        def self.generate_clone_spec(src_config, dc, cpus, memory, datastore, virtual_disks, network, cluster)
          # TODO : A lot of this should be moved to utilities in providers/vsphere.rb
          rspec = Vsphere.get_rspec(dc, cluster)
          rspec.datastore = datastore

          clone_spec = RbVmomi::VIM.VirtualMachineCloneSpec(:location => rspec, :template => false, :powerOn => true)
          clone_spec.config = RbVmomi::VIM.VirtualMachineConfigSpec(:deviceChange => Array.new, :extraConfig => nil)

          network = Vsphere.find_network(network, dc)
          card = src_config.hardware.device.find { |d| d.deviceInfo.label == "Network adapter 1" }
          begin
            switch_port = RbVmomi::VIM.DistributedVirtualSwitchPortConnection(
              :switchUuid => network.config.distributedVirtualSwitch.uuid,
              :portgroupKey => network.key
            )
            card.backing.port = switch_port
          rescue
            card.backing.deviceName = network.name
          end

 	  network_spec = RbVmomi::VIM.VirtualDeviceConfigSpec(:device => card, :operation => "edit")
          clone_spec.config.deviceChange.push network_spec

          virtual_disks.each_with_index do |vd, idx|
            size = vd[:size].to_i
            label = vd[:label].to_i
            key = 2001 + idx # key 2000 -> SCSI0, 2001 -> SCSI1...
            filename = vd[:datastore] || datastore.name

            disk = RbVmomi::VIM.VirtualDisk(
              :key => key,
              :capacityInKB => size * 1024 * 1024,
              :controllerKey => 1000, # SCSI controller
              :unitNumber => idx + 1,
              :backing => RbVmomi::VIM.VirtualDiskFlatVer2BackingInfo(
                :fileName => "[#{filename}]",
                :diskMode => :persistent,
                :thinProvisioned => true,
                :datastore => datastore
              ),
              :deviceInfo => RbVmomi::VIM.Description(
                :label => label, 
                :summary => "%sGB" %[size]
              ),
            )  

            disk_spec = {:operation => :add, :fileOperation => :create, :device => disk }
            clone_spec.config.deviceChange.push disk_spec
          end
          
          clone_spec.config.numCPUs  = Integer(cpus)
          clone_spec.config.memoryMB = Integer(memory) * 1024
 
          clone_spec
        end

        def self.create!(computer)
          return if computer.machine? and computer.machine.created?
          Ironfan.step(computer.name,"creating cloud machine", :green)

          errors = lint(computer)
          if errors.present? then raise ArgumentError, "Failed validation: #{errors.inspect}" ; end

          # TODO: Pass launch_desc to a single function and let it do the rest... like fog does
          launch_desc = launch_description(computer)
          cpus           = launch_desc[:cpus]
          cluster        = launch_desc[:cluster]
          datacenter     = launch_desc[:datacenter]
          datastore      = launch_desc[:datastore]
          memory         = launch_desc[:memory]
          template       = launch_desc[:template] 
          user_data      = launch_desc[:user_data]
          virtual_disks  = launch_desc[:virtual_disks]
          network        = launch_desc[:network]

          datacenter = Vsphere.find_dc(datacenter)
          cluster    = Vsphere.find_in_folder(datacenter.hostFolder, RbVmomi::VIM::ClusterComputeResource, cluster)
          datastore  = Vsphere.find_ds(datacenter, datastore) # Need to add in round robin choosing or something
          src_folder = datacenter.vmFolder

          Ironfan.safely do
            src_vm = Vsphere.find_in_folder(src_folder, RbVmomi::VIM::VirtualMachine, template)
            clone_spec = generate_clone_spec(src_vm.config, datacenter, cpus, memory, datastore, virtual_disks, network, cluster)
            
            vsphere_server = src_vm.CloneVM_Task(:folder => src_vm.parent, :name => computer.name, :spec => clone_spec)
            vsphere_server.wait_for_completion

            # Will break if the VM isn't finished building.  
            new_vm = Vsphere.find_in_folder(src_folder, RbVmomi::VIM::VirtualMachine, computer.name)
            machine = Machine.new(:adaptee => new_vm)
            computer.machine = machine
            remember machine, :id => machine.name

            Ironfan.step(computer.name,"pushing keypair", :green)
            public_key = Vsphere::Keypair.public_key(computer)
            # TODO - Move ReconfigVM_Task into it's own method
            extraConfig = [{:key => 'guestinfo.pubkey', :value => public_key}, 
                           {:key => "guestinfo.user_data", :value => user_data}, 
                           {:key => 'guestinfo.hostname', :value => computer.name}] 
            machine.ReconfigVM_Task(:spec => RbVmomi::VIM::VirtualMachineConfigSpec(:extraConfig => extraConfig)).wait_for_completion
          end
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          # TODO:  Fix this one day when we have multiple "datacenters"
          cloud = cluster.servers.values[0].cloud(:vsphere)
          vm_folder = Vsphere.find_dc(cloud.datacenter).vmFolder
          Vsphere.find_all_in_folder(vm_folder, RbVmomi::VIM::VirtualMachine).each do |fs|
            machine = new(:adaptee => fs)
            if recall? machine.name
              machine.bogus <<                 :duplicate_machines
              recall(machine.name).bogus <<    :duplicate_machines
              remember machine, :append_id => "duplicate:#{machine.config.uuid}"
            else # never seen it
              remember machine
            end
            Chef::Log.debug("Loaded #{machine}")
          end
        end

        def self.destroy!(computer)
          return unless computer.machine?
          forget computer.machine.name
          computer.machine.destroy
        end

        def self.launch_description(computer)
          cloud = computer.server.cloud(:vsphere)
          user_data_hsh =               {
            :chef_server =>             Chef::Config[:chef_server_url],
            :client_key =>              computer.private_key,
            :cluster_name =>            computer.server.cluster_name,
            :facet_index =>             computer.server.index,
            :facet_name =>              computer.server.facet_name,
            :node_name =>               computer.name,
            :organization =>            Chef::Config[:organization],
          }

          description = {
            :cpus                  => cloud.cpus,
            :cluster               => cloud.cluster,
            :datacenter            => cloud.datacenter,
            :datastore             => cloud.datastore, 
            :memory                => cloud.memory,
            :network               => cloud.network, 
            :template              => cloud.template,
            :user_data             => JSON.pretty_generate(user_data_hsh),
            :virtual_disks         => cloud.virtual_disks
          }
          description
        end

        # @returns [Hash{String, Array}] of 'what you did wrong' => [relevant, info]
        def self.lint(computer)
          cloud = computer.server.cloud(:vsphere)
          info  = [computer.name, cloud.inspect]
          errors = {}
          server_errors = computer.server.lint
          errors["Unhappy Server"] = server_errors if server_errors.present?
          errors["Datacenter"] = info if cloud.datacenter.blank?
          errors["Template"] = info if cloud.template.blank?
          errors["Datastore"] = info if cloud.datastore.blank?
          errors['Missing client']      = info            unless computer.client?
          errors['Missing private_key'] = computer.client unless computer.private_key
          #
          errors
        end

        def to_display(style,values={})
          # style == :minimal
          values["State"] =            runtime.powerState rescue "Terminated"
          values["MachineID"] =        config.uuid rescue ""
#          values["Public IP"] =         public_ip_address
          values["Private IP"] =        guest.ipAddress rescue ""
#          values["Created On"] =        created_at.to_date
          return values if style == :minimal

          # style == :default
#          values["Flavor"] =            flavor_id
#          values["AZ"] =                availability_zone
          return values if style == :default

          # style == :expanded
#          values["Image"] =             image_id
          values["Virtual Disks"] =      disks.map { |d| d.backing.fileName }.join(', ')
#          values["SSH Key"] =           key_name
          values
        end

        def ssh_key
          keypair = cloud.keypair || computer.server.cluster_name
        end

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

      end
    end
  end
end
