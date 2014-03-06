module Ironfan
  class Provider
    class Autoscale

      class Machine < Ironfan::IaasProvider::Machine
        delegate :id, :id=, :arn, :arn=, :availability_zones,
            :availability_zones=, :created_at, :created_at=, :default_cooldown,
            :default_cooldown=, :desired_capacity, :desired_capacity=,
            :health_check_grace_period, :health_check_grace_period=, :health_check_type, :health_check_type=,
            :instances, :instances=, :launch_configuration_name,
            :launch_configuration_name=, :load_balancer_names,
            :load_balancer_names=, :max_size, :max_size=, :min_size, :min_size=,
            :placement_group, :placement_group=,
            :suspended_processes, :suspended_processes=,
            :tags, :tags=, :termination_policies,
            :termination_policies=, :vpc_zone_identifier, :vpc_zone_identifier=,
            :activities, :configuration, :disable_metrics_collection,
            :enable_metrics_collection, :instances_in_service,
            :instances_out_service, :resume_processes, :suspend_processes, :ready?,
            :save, :update, :options, :collection, :collection=,
            :connection, :connection=, :reload, :symbolize_keys, :wait_for, :_dump,
            :identity, :identity=, :new_record?, :requires, :requires_one,
          :to => :adaptee

        delegate :image_id, :kernel_id, :kernel_id=, :key_name, :key_name=, :ramdisk_id, :ramdisk_id=,
          :to => :launch_configuration

        include Ironfan::Dsl::Autoscale::DisplayHelper

        def self.shared?()      false;  end
        def self.multiple?()    false;  end
        def self.resource_type()        :machine;   end
        def self.expected_ids(computer) [computer.server.full_name];   end

        def name
          id
        end

        def flavor
          launch_configuration.instance_type
        end

        # Autoscale groups cannot be contacted directly
        def sshable?
          false
        end

        # Do not test ssh or attempt to bootstrap autoscale groups
        def perform_after_launch_tasks?
          false
        end

        def state
          stopped? ? "stopped" : "running"
        end

        def created?
          true
        end

        def running?
          !stopped?
        end

        def stopped?
          suspended_processes.map {|p| p['ProcessName'] }.include?('Launch')
        end

        def launch_configuration
          @launch_configuration ||= Autoscale.connection.configurations.detect{ |c| c.id == adaptee.launch_configuration_name }
        end

        def start
          adaptee.resume_processes
          adaptee.wait_for{ instances_in_service.size >= desired_capacity }
        end

        def stop
          adaptee.suspend_processes
        end

        def destroy
          Ironfan.safely do
            # Terminate all instances

            # Desired capactiy may not be reduced below min size.
            # The fog model appears to not correctly support updates so this has to be set directly.
            adaptee.service.update_auto_scaling_group(id, 'MinSize' => 0, 'DesiredCapacity' => 0, 'HonorCooldown' => false)
            Ironfan.step(id, "Terminating instances in autoscale group. This can take a while.")
            adaptee.wait_for { instances.empty? } # instances (unlike instances_in_service) includes all instances, even terminating ones

            # Remove the group. Sometimes AWS still thinks there are scaling actions going on and this needs to be retried.
            adaptee.wait_for do
              begin
                destroy
              rescue Fog::Compute::AWS::Error => e
                raise unless e =~ /ScalingActivityInProgress/
              end
            end

            # Remove the associated launch
            launch_configuration.destroy
          end
        end

        def to_display(style,values={})
          values["State"] =             state.to_sym
          values["AS Group"] =          name
          values["Created On"] =        created_at.to_date
          return values if style == :minimal

          values["AZ"] =                displayable_availability_zones
          values["Min Size"] =          min_size
          values["Max Size"] =          max_size
          values["Desired"] =           desired_capacity
          return values if style == :default

          values["Image"] =             image_id
          values
        end

        def to_s
          "<%-12s %-25s %-25s %-12s %s>" % [ id, created_at, image_id, flavor, availability_zones.join(',') ]
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Autoscale.connection.groups.each do |asg|
            group = new(:adaptee => asg)
            if (not group.created?)
              next unless Ironfan.chef_config[:include_terminated]
              remember group, :append_id => "terminated:#{group}"
            elsif recall? group.name
              group.bogus <<                   :duplicate_machines
              recall(group.name).bogus <<      :duplicate_machines
              remember group, :append_id => "duplicate:#{group}"
            else # never seen it
              remember group
            end
            Chef::Log.debug("Loaded #{group}")
          end
        end

        def receive_adaptee(obj)
          obj = Autoscale.connection.groups.new(obj) if obj.is_a?(Hash)
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

        class << self
          private

          def user_data(computer)
            server   = computer.server
            hostname = computer.dns_name
            #
            bootstrap = Chef::Knife::Bootstrap.new
            bootstrap.name_args               = [ hostname ]
            bootstrap.config[:computer]       = computer
            bootstrap.config[:server]         = server
            bootstrap.config[:run_list]       = server.run_list
            bootstrap.config[:distro]         = computer.bootstrap_distro
            #
            bootstrap.render_template(IO.read(bootstrap.find_template).chomp)
          end

          def launch_configuration(computer)
            cloud = computer.server.cloud(:autoscale)
            Autoscale.connection.configurations.new.tap do |c|
              c.id                     = computer.name
              c.image_id               = cloud.image_id
              c.instance_type          = cloud.flavor
              c.kernel_id              = cloud.kernel_id
              c.ramdisk_id             = cloud.ramdisk_id
              c.user_data              = user_data(computer)

              Chef::Log.debug(c.inspect)
            end
          end

          def autoscale_group(computer)
            cloud = computer.server.cloud(:autoscale)
            Autoscale.connection.groups.new.tap do |g|
              g.id                            = computer.name
              g.launch_configuration_name     = computer.name

              g.availability_zones            = cloud.availability_zones
              g.default_cooldown              = cloud.default_cooldown
              g.desired_capacity              = cloud.desired_capacity
              g.health_check_grace_period     = cloud.health_check_grace_period
              g.health_check_type             = cloud.health_check_type
              g.max_size                      = cloud.max_size
              g.min_size                      = cloud.min_size
              g.placement_group               = cloud.placement_group
              g.placement_group               = cloud.placement_group
              g.termination_policies          = cloud.termination_policies
              g.vpc_zone_identifier           = cloud.subnet

              g.tags = {
                'cluster' => computer.server.cluster_name,
                'facet'   => computer.server.facet_name
              }.map { |k,v| { 'Key' => k, 'Value' => v, 'PropagateAtLaunch' => true } }

              Chef::Log.debug(g.inspect)
            end
          end
        end

        #
        # Manipulation
        #
        def self.create!(computer)
          return if computer.machine? and computer.machine.created?
          Ironfan.step(computer.name,"creating autoscale group", :green)
          #
          errors = lint(computer)
          if errors.present? then raise ArgumentError, "Failed validation: #{errors.inspect}" ; end
          #
          Ironfan.safely do
            fog_as_group = Autoscale.connection.groups.detect{ |g| g.id == computer.name }

            if fog_as_group
              Chef::Log.debug("Autoscale Group #{fog_as_group.id} already exists.")
            else
              fog_launch_config = launch_configuration(computer)
              begin
                fog_launch_config.save
                fog_launch_config.wait_for { ready? }
              rescue Fog::AWS::AutoScaling::IdentifierTaken
                # The launch configuration already exists and nothing needs to be done
                Chef::Log.debug("Autoscale Launch Config #{fog_launch_config.id} exists")
              end

              fog_as_group = autoscale_group(computer)
              fog_as_group.save
            end

            machine = Machine.new(:adaptee => fog_as_group)
            computer.machine = machine
            remember machine, :id => computer.name
          end
        end

        def self.lint(computer)
          cloud = computer.server.cloud(:autoscale)
          info = [computer.name, cloud.inspect]
          errors = {}
          # TODO
          errors
        end

        def self.destroy!(computer)
          return unless computer.machine?
          forget computer.machine.name

          computer.machine.destroy
          computer.machine.reload            # show the node as shutting down
        end

        def self.save!(computer)
          Ironfan.unless_dry_run do
            Ironfan.safely do
              # TODO ?
            end
          end
        end

      end
    end
  end
end
