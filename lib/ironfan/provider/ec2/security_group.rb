module Ironfan
  class Provider
    class Ec2

      class SecurityGroup < Ironfan::Provider::Resource
        delegate :_dump, :authorize_group_and_owner, :authorize_port_range,
            :collection, :collection=, :connection, :connection=, :description,
            :description=, :destroy, :group_id, :group_id=, :identity,
            :identity=, :ip_permissions, :ip_permissions=, :name, :name=,
            :new_record?, :owner_id, :owner_id=, :reload, :requires,
            :requires_one, :revoke_group_and_owner, :revoke_port_range, :save,
            :symbolize_keys, :vpc_id, :vpc_id=, :wait_for,
          :to => :adaptee

        def self.shared?()      true;   end
        def self.multiple?()    true;   end
        def self.resource_type()        :security_group;   end
        def self.expected_ids(computer)
          ec2 = computer.server.cloud(:ec2)
          ec2.security_groups.keys.map do |name|
            ec2.vpc ? "#{ec2.vpc}:#{name.to_s}" : name.to_s
          end.uniq
        end

        def name()
          return adaptee.name if adaptee.vpc_id.nil?
          "#{adaptee.vpc_id}:#{adaptee.name}"
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Ec2.connection.security_groups.each do |raw|
            next if raw.blank?
            sg = SecurityGroup.new(:adaptee => raw)
            remember(sg)
            Chef::Log.debug("Loaded #{sg}: #{sg.inspect}")
          end
        end

        def receive_adaptee(obj)
          obj = Ec2.connection.security_groups.new(obj) if obj.is_a?(Hash)
          super
        end

        def to_s
          if ip_permissions.present?
            perm_str = ip_permissions.map{|perm|
              "%s:%s-%s (%s | %s)" % [
                perm['ipProtocol'], perm['fromPort'], perm['toPort'],
                perm['groups'  ].map{|el| el['groupName'] }.join(','),
                perm['ipRanges'].map{|el| el['cidrIp']    }.join(','),
              ]
            }
            return "<%-15s %-12s %-25s %s>" % [ self.class.handle, group_id, name, perm_str]
          else
            return "<%-15s %-12s %s>" % [ self.class.handle, group_id, name ]
          end
        end

        #
        # Manipulation
        #

        def self.create!(computer)
          return unless Ec2.applicable computer

          ensure_groups(computer)
          groups = self.expected_ids(computer)
          # Only handle groups that don't already exist
          groups.delete_if {|group| recall? group.to_s }
          return if groups.empty?

          Ironfan.step(computer.server.cluster_name, "creating security groups", :blue)
          groups.each do |group|
            Ironfan.step(group, "  creating #{group} security group", :blue)
            begin
              tokens    = group.to_s.split(':')
              group_id  = tokens.pop
              vpc_id    = tokens.pop
              Ec2.connection.create_security_group(group_id,"Ironfan created group #{group_id}",vpc_id)
            rescue Fog::Compute::AWS::Error => e # InvalidPermission.Duplicate
              Chef::Log.info("ignoring security group error: #{e}")
              sleep 0.5  # quit racing so hard
            end
          end
          load! # Get the native groups via reload
        end

        def self.recall_with_vpc(name,vpc_id=nil)
          group_name = vpc_id.nil? ? name : "#{vpc_id}:#{name}"
          recall(group_name)
        end

        def self.save!(computer)
          return unless Ec2.applicable computer
          cloud = computer.server.cloud(:ec2)

          create!(computer)            # Make sure the security groups exist
          security_groups = cloud.security_groups.values
          dsl_groups = security_groups.select do |dsl_group|
            not (recall_with_vpc(dsl_group,cloud.vpc)) and \
            not (dsl_group.range_authorizations +
                 dsl_group.group_authorized_by +
                 dsl_group.group_authorized).empty?
          end.compact
          return if dsl_groups.empty?

          Ironfan.step(computer.server.cluster_name, "ensuring security group permissions", :blue)
          dsl_groups.each do |dsl_group|
            dsl_group_fog = recall_with_vpc(dsl_group.name,cloud.vpc)
            dsl_group.group_authorized.each do |other_group|
              other_group_fog = recall_with_vpc(other_group,cloud.vpc)
              Ironfan.step(dsl_group.name, "  ensuring access from #{other_group}", :blue)
              options = {:group => other_group_fog.group_id}
              safely_authorize(dsl_group_fog, 1..65535, options)
            end

            dsl_group.group_authorized_by.each do |other_group|
              other_group_fog = recall_with_vpc(other_group,cloud.vpc)
              Ironfan.step(dsl_group.name, "  ensuring access to #{other_group}", :blue)
              options = {:group => dsl_group_fog.group_id}
              safely_authorize(other_group_fog, 1..65535, options)
            end

            dsl_group.range_authorizations.each do |range_auth|
              range, cidr, protocol = range_auth
              step_message = "  ensuring #{protocol} access from #{cidr} to #{range}"
              Ironfan.step(dsl_group.name, step_message, :blue)
              options = {:cidr_ip => cidr, :ip_protocol => protocol}
              safely_authorize(dsl_group_fog, range, options)
            end
          end
        end

        #
        # Utility
        #
        def self.ensure_groups(computer)
          return unless Ec2.applicable computer
          # Ensure the security_groups include those for cluster & facet
          # FIXME: This violates the DSL's immutability; it should be
          #   something calculated from within the DSL construction
          Ironfan.todo("CODE SMELL: violation of DSL immutability: #{caller}")
          cloud = computer.server.cloud(:ec2)
          c_group = cloud.security_group(computer.server.cluster_name)
          c_group.authorized_by_group(c_group.name)
          facet_name = "#{computer.server.cluster_name}-#{computer.server.facet_name}"
          cloud.security_group(facet_name)
        end

        # Try an authorization, ignoring duplicates (this is easier than correlating).
        # Do so for both TCP and UDP, unless only one is specified
        def self.safely_authorize(fog_group,range,options)
          unless options[:ip_protocol]
            safely_authorize(fog_group,range,options.merge(:ip_protocol => 'tcp'))
            safely_authorize(fog_group,range,options.merge(:ip_protocol => 'udp'))
            return
          end

          begin
            fog_group.authorize_port_range(range,options)
          rescue Fog::Compute::AWS::Error => e      # InvalidPermission.Duplicate
            Chef::Log.info("ignoring #{e}")
          end
        end
      end

    end
  end
end
