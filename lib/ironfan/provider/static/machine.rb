module Ironfan
  class Provider
    class Static
      class Machine < Ironfan::IaasProvider::Machine

        def self.shared?()      false;  end
        def self.multiple?()    false;  end
        def self.resource_type()        :machine;   end
        def self.expected_ids(computer) [computer.server.full_name];   end

        def name()  adaptee.full_name; end
        def tags
          t = {"Name" => @adaptee.name}
          return t.keys.inject({}) {|h,k| h[k]=t[k]; h[k.to_sym]=t[k]; h}
        end

        def vpc_id
          return nil
        end

        def created_at
          nil
        end

        def flavor_id
          return nil
        end

        def flavor_name
          "nil"
        end

        def image_id
          "none"
        end

        def groups           ; []   ;   end

        def public_hostname    ; adaptee.cloud(:static).public_hostname || public_ip_address ; end
        def public_ip_address  ; adaptee.cloud(:static).public_ip || private_ip_address ; end
        def dns_name            ; public_ip_address ; end

        def keypair          ; adaptee.cloud(:static).keypair ; end

        def created?
          false
        end
        def pending?
          false
        end
        def running?
          true
        end
        def stopping?
          false
        end

        def stopped?
          false
        end
        
        def error?
          false
        end

        def start
        end

        def stop
        end

        def perform_after_launch_tasks?
          true
        end

        def to_display(style,values={})
          # style == :minimal
          values["State"] =             "???"
          values["MachineID"] =         private_ip_address
          values["Public IP"] =         private_ip_address
          values["Private IP"] =        public_ip_address
          values["Created On"] =        "???"
          return values if style == :minimal

          # style == :default
          values["Flavor"] =            nil
          values["AZ"] =                nil
          return values if style == :default

          # style == :expanded
          values["Image"] =             "none"
          #values["Volumes"] =           volumes.map(&:id).join(', ')
          values["SSH Key"] =           "none"
          values
        end

        def ssh_key
          keypair = cloud.keypair || computer.server.cluster_name
        end

        def key_name
          keypair
        end

        def private_ip_address
          adaptee.cloud(:static).private_ip
        end

        def availability_zone
          'none'
        end

        def destroy
        end

        def to_s
          "<%-15s %-12s %-25s %-25s %-15s %-15s %-12s %-12s %s:%s>" % [
            self.class.handle, "", created_at, name, private_ip_address, public_ip_address, flavor_name, availability_zone, key_name, groups.join(',') ]
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          cluster.facets.each do |facet| 
            facet.servers.each do |server|
              machine = new(:adaptee => server)
              remember machine
            end
          end
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
          nil
        end

        # @returns [Hash{String, Array}] of 'what you did wrong' => [relevant, info]
        def self.lint(computer)
          cloud = computer.server.cloud(:static)
          info  = [computer.name, cloud.inspect]
          errors = {}
          server_errors = computer.server.lint
          errors["No Private IP"]       = info if cloud.private_ip.blank?
          errors
        end

        def self.launch_description(computer)
          nil
        end

        # An array of hashes with dorky-looking keys, just like Fog wants it.
        def self.block_device_mapping(computer)
          []
        end

        def self.destroy!(computer)
          return unless computer.machine?
          forget computer.machine.name
          computer.machine.destroy
          computer.machine.reload            # show the node as shutting down
        end

        def self.save!(computer)
          return unless computer.machine?
          return unless computer.created?
          nil
        end
      end
    end
  end
end
