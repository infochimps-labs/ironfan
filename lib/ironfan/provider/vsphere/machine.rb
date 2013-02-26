module Ironfan
  class Provider
    class Vsphere

      class Machine < Ironfan::IaasProvider::Machine
        delegate :config, :connection, :connection=, :Destroy_Task, :guest, :PowerOffVM_Task, 
          :PowerOnVM_Task, :powerState, :runtime,
          :to => :adaptee

        def self.shared?()      false;  end
        def self.multiple?()    false;  end
        def self.resource_type()        :machine;   end
        def self.expected_ids(computer) [computer.server.full_name];   end 
        
        def name
           return config.name
        end

        def vpc_id
          return nil
        end

        def public_ip_address
          # TODO: Fix me.  
          return "10.10.0.79"
        end
 
        def public_hostname
          # TODO: Fix me
          return nil
        end

        def destroy
          adaptee.PowerOffVM_Task.wait_for_completion unless adaptee.runtime.powerState == "poweredOff"
          adaptee.Destroy_Task.wait_for_completion
        end

        def created?
          "yes"
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
          adaptee.PowerOffVM_Task.wait_for_completion
        end

        def self.generate_clone_spec(src_config, vsphere_dc)
          dc = Vsphere.find_dc(vsphere_dc)
          rspec = Vsphere.get_rspec(dc)
          clone_spec = RbVmomi::VIM.VirtualMachineCloneSpec(:location => rspec, :template => false, :powerOn => true)
          clone_spec.config = RbVmomi::VIM.VirtualMachineConfigSpec(:deviceChange => Array.new)

          network = Vsphere.find_network("VM Network", dc)
          card = src_config.hardware.device.find { |d| d.deviceInfo.label == "Network adapter 1" }
          begin
            switch_port = RbVmomi::VIM.DistributedVirtualSwitchPortConnection(
                            :switchUuid => network.config.distributedVirtualSwitch.uuid,
                            :portgroupKey => network.key )

            card.backing.port = switch_port
          rescue
            card.backing.deviceName = network.name
          end

 	  network_spec = RbVmomi::VIM.VirtualDeviceConfigSpec(:device => card, :operation => "edit")
          clone_spec.config.deviceChange.push network_spec

     #     if get_config(:customization_cpucount)
     #       clone_spec.config.numCPUs = get_config(:customization_cpucount)
     #     end

     #     if get_config(:customization_memory)
     #       clone_spec.config.memoryMB = Integer(get_config(:customization_memory)) * 1024
     #     end
 
          clone_spec
          
        end

        def self.create!(computer)
          return if computer.machine? and computer.machine.created?
          Ironfan.step(computer.name,"creating cloud machine", :green)
          #
#          errors = lint(computer)
#          if errors.present? then raise ArgumentError, "Failed validation: #{errors.inspect}" ; end
          #

          launch_desc = launch_description(computer)
          Chef::Log.debug(JSON.pretty_generate(launch_desc))

          src_folder = Vsphere.find_dc("New Datacenter").vmFolder

          Ironfan.safely do
            src_vm = Vsphere.find_in_folder(src_folder, RbVmomi::VIM::VirtualMachine, "Ubuntu 12.04 Template")
            clone_spec = generate_clone_spec(src_vm.config, "New Datacenter")
            dest_folder = src_folder
            vsphere_server = src_vm.CloneVM_Task(:folder => dest_folder, :name => computer.name, :spec => clone_spec)
            vsphere_server.wait_for_completion

            # Will break if the VM isn't finished building.  
            new_vm = Vsphere.find_in_folder(src_folder, RbVmomi::VIM::VirtualMachine, computer.name)
            machine = Machine.new(:adaptee => new_vm)
            computer.machine = machine
            remember machine, :id => machine.name
          end

        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          vm_folder = Vsphere.find_dc("New Datacenter").vmFolder
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
        end

        def self.launch_description(computer)
          cloud = computer.server.cloud(:ec2)
          user_data_hsh =               {
            :chef_server =>             Chef::Config[:chef_server_url],
            :node_name =>               computer.name,
            :organization =>            Chef::Config[:organization],
            :cluster_name =>            computer.server.cluster_name,
            :facet_name =>              computer.server.facet_name,
            :facet_index =>             computer.server.index,
            :client_key =>              computer.private_key,

          }

          description = {
#            :template_directory    => cloud.template_directory,
#            :datacenter            => cloud.vsphere_datacenter,
#            :vpc_id               => cloud.vpc,
#            :subnet_id            => cloud.subnet,
#            :key_name             => cloud.ssh_key_name(computer),
            :user_data            => JSON.pretty_generate(user_data_hsh),
#            :block_device_mapping => block_device_mapping(computer),
#            :availability_zone    => cloud.default_availability_zone,
#            :monitoring           => cloud.monitoring
          }
        end

        def to_display(style,values={})
          # style == :minimal
          puts "Broke!"
          values["State"] =            runtime.powerState
          values["MachineID"] =        config.uuid
#          values["Public IP"] =         public_ip_address
          values["Private IP"] =        guest.ipAddress
#          values["Created On"] =        created_at.to_date
          return values if style == :minimal

          # style == :default
#          values["Flavor"] =            flavor_id
#          values["AZ"] =                availability_zone
          return values if style == :default

          # style == :expanded
#          values["Image"] =             image_id
#          values["Volumes"] =           volumes.map(&:id).join(', ')
#          values["SSH Key"] =           key_name
          values
        end

      end
    end
  end
end
