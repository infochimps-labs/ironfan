module Ironfan
  class Provider
    class Rds

      class Machine < Ironfan::IaasProvider::Machine
        delegate :availability_zone, :created_at, :desstroy, :endpoint, :engine,
          :engine_version, :destroy, :flavor_id, :id, :id=, :name, :state, :add_tags, 
          :tags, 
          :to => :adaptee

        def self.shared?()      false;  end
        def self.multiple?()    false;  end
        def self.resource_type()        :machine;   end
        def self.expected_ids(computer) [computer.server.full_name];   end

        def name
          return id if tags.empty?
          tags["Name"] || tags["name"] || id
        end

        def public_hostname  ; dns_name ; end
 
        def created?
          not ['terminated', 'shutting-down'].include? state
        end

        def deleting?
          state == "deleting"
        end

        def pending?
          state == "pending"
        end

        def creating?
          state == "creating"
        end

        def rebooting?
          state == "rebooting"
        end

        def available?
          state == "available"
        end
      
        def stopped? 
        end

        def perform_after_launch_tasks?
          false
        end

        def to_display(style,values={})
          # style == :minimal
          values["State"] =             state.to_sym
          values["MachineID"] =         id
          values["Endpoint"]  =         endpoint[:Address]
          values["Created On"] =        created_at.to_date
          return values if style == :minimal

          # style == :default
          values["Flavor"] =            flavor_id
          values["AZ"] =                availability_zone
          return values if style == :default

          # style == :expanded
          values["Engine"]  =           engine
          values["EngineVersion"] =     engine_version
          values
        end

        def to_s
          "<%-15s %-12s %-25s %-25s %-15s %-15s>" % [
            self.class.handle, id, created_at, tags['name'], flavor_id, availability_zone]
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Rds.connection.servers.each do |fs|
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
            Chef::Log.debug("Loaded #{machine}")
          end
        end

        def receive_adaptee(obj)
          obj = Rds.connection.servers.new(obj) if obj.is_a?(Hash)
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
          return if computer.machine? and computer.machine.created?
          Ironfan.step(computer.name,"creating RDS machine... go grab some a beer or two.", :green)
          #
          errors = lint(computer)
          if errors.present? then raise ArgumentError, "Failed validation: #{errors.inspect}" ; end
          #
          launch_desc = launch_description(computer)
          launch_desc[:id] = computer.name
          Chef::Log.debug(JSON.pretty_generate(launch_desc))

          Ironfan.safely do
            fog_server = Rds.connection.servers.create(launch_desc)
            machine = Machine.new(:adaptee => fog_server)
            computer.machine = machine
            remember machine, :id => computer.name

            Ironfan.step(fog_server.id,"waiting for machine to be ready", :gray)
            Ironfan.tell_you_thrice     :name           => fog_server.id,
                                        :problem        => "server unavailable",
                                        :error_class    => Fog::Errors::Error do
              fog_server.wait_for { ready? }
            end
          end

          # tag the computer correctly
          tags = {
            'cluster' =>      computer.server.cluster_name,
            'facet' =>        computer.server.facet_name,
            'index' =>        computer.server.index,
            'name' =>         computer.name,
            'Name' =>         computer.name,
          }
          Rds.ensure_tags(tags, computer.machine)
        end

        # @returns [Hash{String, Array}] of 'what you did wrong' => [relevant, info]
        def self.lint(computer)
          cloud = computer.server.cloud(:ec2)
          info  = [computer.name, cloud.inspect]
          errors = {}
#          server_errors = computer.server.lint
#          errors["Unhappy Server"]      = server_errors   if server_errors.present?
#          errors["No AMI found"]        = info            if cloud.image_id.blank?
#          errors['Missing client']      = info            unless computer.client?
#          errors['Missing private_key'] = computer.client unless computer.private_key
#          #
#          all_asserted_regions = [Ec2.connection.region, cloud.region, Chef::Config[:knife][:region], Ironfan.chef_config[:region]].compact.uniq
#          errors["mismatched region"] = all_asserted_regions unless all_asserted_regions.count == 1
#          #
          errors
        end

        def self.launch_description(computer)
          cloud = computer.server.cloud(:rds)
          user_data_hsh =               {
            :chef_server =>             Chef::Config[:chef_server_url],
            :node_name =>               computer.name,
            :organization =>            Chef::Config[:organization],
            :cluster_name =>            computer.server.cluster_name,
            :facet_name =>              computer.server.facet_name,
            :facet_index =>             computer.server.index,
          }


          # main machine info
          # note that Fog does not actually create tags when it creates a
          #  server; they and permanence are applied during sync
          description = {
            :allocated_storage            => cloud.size,
            :auto_minor_version_upgrade   => cloud.autoupgrade,
            :availability_zone            => cloud.default_availability_zone,
            :backup_retention_period      => cloud.backup_retention,
            :db_security_groups           => cloud.security_groups.keys,
            :engine                       => cloud.engine,
            :engine_version               => cloud.version,
            :flavor_id                    => cloud.flavor,
            :license_model                => cloud.license_model,
            :master_username              => cloud.username,
            :password                     => cloud.password,
            :port                         => cloud.port,
            :preferred_backup_window      => cloud.preferred_backup_window,
            :preferred_maintenance_window => cloud.preferred_maintenance_window,
            :user_data                    => JSON.pretty_generate(user_data_hsh),
#            :db_name                      => cloud.dbname,  # Breaks for some reason
#            :charset                    => cloud.charset, # Not supported in FOG?
#            :iops                       => cloud.iops, # Not supported in FOG?
#            :multi_az                    => cloud.multi_availability_zone,
          }

          description
        end

#          # VPC security_groups can only be addressed by id (not name)
#          description[:security_group_ids] = cloud.security_groups.keys.map do |g|
#            SecurityGroup.recall( SecurityGroup.group_name_with_vpc(g,cloud.vpc) ).group_id
#          end
#
#          description[:iam_server_certificates] = cloud.iam_server_certificates.values.map do |cert|
#            IamServerCertificate.recall(IamServerCertificate.full_name(computer, cert))
#          end.compact.map(&:name)
#
#          description[:elastic_load_balancers] = cloud.elastic_load_balancers.values.map do |elb|
#            ElasticLoadBalancer.recall(ElasticLoadBalancer.full_name(computer, elb))
#          end.compact.map(&:name)
#
#          if cloud.flavor_info[:placement_groupable]
#            ui.warn "1.3.1 and earlier versions of Fog don't correctly support placement groups, so your nodes will land willy-nilly. We're working on a fix"
#            description[:placement] = { 'groupName' => cloud.placement_group.to_s }
#          end
#          if cloud.flavor_info[:ebs_optimizable]
#            description[:ebs_optimized] = cloud.ebs_optimized
#          end
#          description
#        end
#
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
#          permanent = computer.server.cloud(:ec2).permanent
          return unless computer.created?
#          Ironfan.step(computer.name, "setting termination flag #{permanent}", :blue)
#          Ironfan.unless_dry_run do
#            Ironfan.safely do
#              Ec2.connection.modify_instance_attribute( computer.machine.id,
#                {'DisableApiTermination.Value' => computer.permanent?, })
            #end
          #end
        end
      end

    end
  end
end
