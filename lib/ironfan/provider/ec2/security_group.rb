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
        field :ensured,        :boolean,       :default => false

        def self.shared?()      true;   end
        def self.multiple?()    true;   end
        def self.resource_type()        :security_group;   end
        def self.expected_ids(computer)
          computer.server.cloud(:ec2).security_groups.keys.map{|k| k.to_s}.uniq
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Ec2.connection.security_groups.each do |raw|
            next if raw.blank?
            sg = SecurityGroup.new(:adaptee => raw)
            remember(sg)
            Chef::Log.debug("Loaded #{sg}")
          end
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
            Ec2.connection.create_security_group(group.to_s,"Ironfan created group #{group}")
          end
          load! # Get the native groups via reload
        end

        def self.save!(computer)
          return unless Ec2.applicable computer

          create!(computer)            # Make sure the security groups exist
          security_groups = computer.server.cloud(:ec2).security_groups.values
          dsl_groups = security_groups.select do |dsl_group|
            not (recall? dsl_group or recall(dsl_group.name).ensured) and \
            not (dsl_group.range_authorizations +
                 dsl_group.group_authorized_by +
                 dsl_group.group_authorized).empty?
          end.compact
          return if dsl_groups.empty?

          Ironfan.step(computer.server.cluster_name, "ensuring security group permissions", :blue)
          dsl_groups.each do |dsl_group|
            dsl_group.group_authorized.each do |other_group|
              Ironfan.step(dsl_group.name, "  ensuring access from #{other_group}", :blue)
              options = {:group => "#{Ec2.aws_account_id}:#{other_group}"}
              safely_authorize(dsl_group.name,1..65535,options)
            end

            dsl_group.group_authorized_by.each do |other_group|
              Ironfan.step(dsl_group.name, "  ensuring access to #{other_group}", :blue)
              options = {:group => "#{Ec2.aws_account_id}:#{dsl_group.name}"}
              safely_authorize(other_group,1..65535,options)
            end

            dsl_group.range_authorizations.each do |range_auth|
              range, cidr, protocol = range_auth
              step_message = "  ensuring #{protocol} access from #{cidr} to #{range}"
              Ironfan.step(dsl_group.name, step_message, :blue)
              options = {:cidr_ip => cidr, :ip_protocol => protocol}
              safely_authorize(dsl_group.name,range,options)
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
        def self.safely_authorize(group_name,range,options)
          unless options[:ip_protocol]
            safely_authorize(group_name,range,options.merge(:ip_protocol => 'tcp'))
            safely_authorize(group_name,range,options.merge(:ip_protocol => 'udp'))
            return
          end

          fog_group = recall(group_name) or raise "unrecognized group: #{group_name}"
          begin
            fog_group.authorize_port_range(range,options)
          rescue Fog::Compute::AWS::Error => e      # InvalidPermission.Duplicate
            Chef::Log.debug("ignoring #{e}")
          end
        end
      end

    end
  end
end
