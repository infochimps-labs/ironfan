module Ironfan
  class Provider
    class Ec2

      class ElasticLoadBalancer < Ironfan::Provider::Resource
        delegate :availability_zones,
          :configure_health_check,
          :deregister_instances,
          :disable_availability_zones,
          :enable_availability_zones,
          :health_check,
          :instances,
          :listeners,
          :policies,
          :register_instances,
          :source_group,
          :to => :adaptee

        def self.shared?()       true;   end
        def self.multiple?()     true;   end
        def self.resource_type() :elastic_load_balancer;   end
        def self.expected_ids(computer)
          ec2 = computer.server.cloud(:ec2)
          ec2.elastic_load_balancers.values.map { |elb| self.full_name(computer, elb) }.uniq
        end

        def name()
          adaptee.id
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Ec2.elb.load_balancers.each do |raw|
            next if raw.blank?
            elb = ElasticLoadBalancer.new(:adaptee => raw)
            remember(elb)
            Chef::Log.debug("Loaded #{elb}: #{elb.inspect}")
          end
        end

        def receive_adaptee(obj)
          obj = Ec2.elb.load_balancer.new(obj) if obj.is_a?(Hash)
          super
        end

        def to_s
          "<%-15s>" % name
        end

        #
        # Manipulation
        #
        def self.aggregate!(computers)
          ec2_computers = computers.select { |c| Ec2.applicable c }
          return if ec2_computers.empty?

          load! # Find out which ELBs already exist in EC2

          running_computers = ec2_computers.select { |c| c.running? }
          elbs_for_running_computers = running_computers.map { |c| self.expected_ids(c) }.flatten.uniq
          elbs_for_stopped_computers = ec2_computers.select { |c| not c.running? }.map { |c| self.expected_ids(c) }.flatten.uniq
          elbs_to_start = [ elbs_for_running_computers ].flatten.compact.reject { |elb_name| recall? elb_name }
          elbs_to_stop  = [ elbs_for_stopped_computers - elbs_for_running_computers ].flatten.compact.select { |elb_name| recall? elb_name }

          elbs_to_stop.each do |elb_name|
            Ironfan.step(elb_name, "stopping unused elastic load balancer #{elb_name}", :blue)
            Ec2.elb.delete_load_balancer(elb_name)
            forget elb_name
          end

          [ elbs_to_start, elbs_for_running_computers ].flatten.sort.uniq.each do |elb_name|
            computers_using_this_elb = running_computers.select { |c| self.expected_ids(c).include?(elb_name) }
            self.start_or_sync_elb(elb_name, computers_using_this_elb, elbs_to_start.include?(elb_name))
          end
          load!

        end

        private

        def self.start_or_sync_elb(elb_name, computers, start_elb)

          # We'll need to know which computers are using this ELB. There must be some, or
          # we wouldn't be in this method.
          availability_zones = computers.map { |c| c.machine.availability_zone }.uniq.sort
          health_check, listeners, ssl_policy = self.fog_elb_parameters(elb_name, computers.first)

          if start_elb
            Ironfan.step(elb_name, "creating elastic load balancer", :blue)
            self.patiently(elb_name, Fog::AWS::IAM::NotFound, :message => "waiting for SSL certificate(s) to appear", :display => true) do
              Ec2.elb.create_load_balancer(availability_zones, elb_name, listeners)
            end
            load! # Repopulate known list with native ELB object
          end

          elb = recall(elb_name)
          Ironfan.step(elb.name, "syncing elastic load balancer", :blue)

          # Did the list of availability zones for this ELB change?
          if availability_zones != elb.availability_zones.sort
            Ironfan.step(elb.name, "  updating availability zones to #{availability_zones.join(', ')}", :blue)
            to_add    = availability_zones - elb.availability_zones
            to_remove = elb.availability_zones - availability_zones
            elb.enable_availability_zones(to_add) unless to_add.empty?
            elb.disable_availability_zones(to_remove) unless to_remove.empty?
          end

          # Did the health check configuration change?
          if health_check != elb.health_check
            Ironfan.step(elb.name, "  updating health check", :blue)
            elb.configure_health_check(health_check)
          end

          # Make sure SSL policy exists and is set on all SSL-enabled load balancer ports
          Ironfan.step(elb.name, "  syncing generated policy #{ssl_policy[:name]}", :blue)
          Ec2.elb.create_load_balancer_policy(elb.name, ssl_policy[:name], 'SSLNegotiationPolicyType', ssl_policy[:attributes])

          # Did the listener configuration change?
          all_lb_ports = listeners.map { |l| l['LoadBalancerPort'] }.sort.uniq
          remove_listeners = [ ]
          elb.listeners.each do |el|
            match = listeners.detect { |l|
              l['Protocol'].eql?(el.protocol) &&
                l['LoadBalancerPort'].eql?(el.lb_port) &&
                l['InstanceProtocol'].eql?(el.instance_protocol) &&
                l['InstancePort'].eql?(el.instance_port) &&
                l['SSLCertificateId'].eql?(el.ssl_id)
            }
            if match
              listeners.reject! { |l| l.eql? match }
            else
              remove_listeners << el.lb_port
            end
          end

          reload = false
          unless remove_listeners.empty?
            Ironfan.step(elb.name, "  removing listener from ports #{remove_listeners.join(', ')}", :blue)
            Ec2.elb.delete_load_balancer_listeners(elb.name, remove_listeners)
            reload = true
          end

          unless listeners.empty?
            Ironfan.step(elb.name, "  adding listeners on ports #{listeners.map { |l| l['LoadBalancerPort'] }.join(', ')}", :blue)
            self.patiently(elb_name, Fog::AWS::IAM::NotFound, :message => "waiting for SSL certificate(s) to appear", :display => true) do
              Ec2.elb.create_load_balancer_listeners(elb.name, listeners)
            end
            reload = true
          end

          if reload
            forget elb.name
            Ironfan.step(elb.name, "  reloading from EC2", :blue)
            load!
            elb = recall elb.name
          end

          removed_policies = [ ]
          elb.listeners.each do |l|
            l.policy_names.reject { |p| p == ssl_policy[:name] }.each do |remove|
              removed_policies << remove
              Ironfan.step(elb.name, "  removing unused policy #{remove} from port #{l.lb_port} listener", :blue)
            end
            if l.ssl_id and !l.policy_names.include?(ssl_policy[:name])
              Ironfan.step(elb.name, "  adding policy #{ssl_policy[:name]} to port #{l.lb_port} listener", :blue)
              Ec2.elb.set_load_balancer_policies_of_listener(elb.name, l.lb_port, [ ssl_policy[:name] ])
            end
          end

          removed_policies.each do |remove|
            Ironfan.step(elb.name, "  deleting now-unused policy #{remove}", :blue)
            Ec2.elb.delete_load_balancer_policy(elb.name, remove)
          end

          # Did the list of instances change?
          running_instances = computers.map { |c| c.machine.id }.sort
          if running_instances != elb.instances.sort
            Ironfan.step(elb.name, "  updating instance list", :blue)
            to_add    = running_instances - elb.instances
            unless to_add.empty?
              Ironfan.step(elb.name, "  adding instances #{to_add.join(', ')}", :blue)
              elb.register_instances(to_add)
            end
            to_remove = elb.instances - running_instances
            unless to_remove.empty?
              Ironfan.step(elb.name, "  removing instances #{to_remove.join(', ')}", :blue)
              elb.deregister_instances(to_remove)
            end
          end

          # Make sure that all of the relevant security groups allow access to the ELB
          # on the health check and listener ports
          elb_sg = elb.source_group
          all_facet_sgs = computers.map { |c| "#{c.server.cluster_name}-#{c.server.facet_name}" }.uniq.map do |sg_name|
            Ironfan::Provider::Ec2::SecurityGroup.recall sg_name
          end

          all_facet_sgs.map do |facet_sg|
            self.patiently(facet_sg.name, Fog::Compute::AWS::Error, :ignore => Proc.new { |e| e.message =~ /InvalidPermission\.Duplicate/ }) do
              facet_sg.authorize_port_range(1..65535, :group => { elb_sg['OwnerAlias'] => elb_sg['GroupName'] })
            end
          end

        end

        def self.full_name(computer, elb)
          "ironfan-%s-%s" % [ computer.server.cluster_name, elb.name ]
        end

        def self.fog_elb_parameters(elb_name, computer)
          elb_name = elb_name.sub("ironfan-#{computer.server.cluster_name}-", '')
          cloud    = computer.server.cloud(:ec2)
          elb      = cloud.elastic_load_balancers[elb_name]

          # Health checking parameters
          health_check = elb.health_check.to_fog

          # Port/protocol listening configurations
          cert_lookup = { }
          cloud.iam_server_certificates.keys.each do |cert_key|
            cert = cloud.iam_server_certificates[cert_key]
            id = Ironfan::Provider::Ec2::IamServerCertificate.expected_id(computer, cert)
            cert_lookup[cert_key] = Ironfan::Provider::Ec2::IamServerCertificate.recall(id)['Arn']
          end
          listeners  = elb.listeners_to_fog(cert_lookup)

          # The SSL policy, if any, for this ELB
          ssl_policy = elb.ssl_policy_to_fog

          # A list of parameters that can be used in Fog calls
          [ health_check, listeners, ssl_policy ]
        end

      end
    end
  end
end
