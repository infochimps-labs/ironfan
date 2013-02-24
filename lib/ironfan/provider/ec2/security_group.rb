module Ironfan
  class Provider
    class Ec2

      class SecurityGroup < Ironfan::Provider::Resource

        WIDE_OPEN = Range.new(1,65535)

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
          return unless computer.server
          ec2 = computer.server.cloud(:ec2)
          ec2.security_groups.keys.map { |name| group_name_with_vpc(name,ec2.vpc) }.uniq
        end

        def name()
          self.class.group_name_with_vpc(adaptee.name, adaptee.vpc_id)
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Ec2.connection.security_groups.reject { |raw| raw.blank? }.each do |raw|
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

        def self.prepare!(computers)

          # Create any groups that don't yet exist, and ensure any authorizations
          # that are required for those groups
          cluster_name             = nil
          groups_to_create         = [ ]
          authorizations_to_ensure = [ ]

          # First, deduce the list of all groups to which at least one instance belongs
          # We'll use this later to decide whether to create groups, or authorize access,
          # using a VPC security group or an EC2 security group.
          groups_that_should_exist = computers.map{|comp| expected_ids(comp) }.flatten.compact.sort.uniq
          groups_to_create << groups_that_should_exist

          computers.select { |computer| Ec2.applicable computer }.each do |computer|
            ensure_groups(computer) # Add facet and cluster security groups for the computer
            cloud           = computer.server.cloud(:ec2)
            cluster_name    = computer.server.cluster_name

            # Iterate over all of the security group information, keeping track of
            # any groups that must exist and any authorizations that must be ensured
            cloud.security_groups.values.each do |dsl_group|

              groups_to_create << dsl_group.name

              groups_to_create << dsl_group.group_authorized.map do |other_group|
                most_appropriate_group_name(other_group, cloud.vpc, groups_that_should_exist)
              end

              groups_to_create << dsl_group.group_authorized_by.map do |other_group|
                most_appropriate_group_name(other_group, cloud.vpc, groups_that_should_exist)
              end

              authorizations_to_ensure << dsl_group.group_authorized.map do |other_group|
                {
                  :grantor      => most_appropriate_group_name(dsl_group.name, cloud.vpc, groups_that_should_exist),
                  :grantee      => most_appropriate_group_name(other_group, cloud.vpc, groups_that_should_exist),
                  :grantee_type => :group,
                  :range        => WIDE_OPEN,
                }
              end

              authorizations_to_ensure << dsl_group.group_authorized_by.map do |other_group|
                {
                  :grantor      => most_appropriate_group_name(other_group, cloud.vpc, groups_that_should_exist),
                  :grantee      => most_appropriate_group_name(dsl_group.name, cloud.vpc, groups_that_should_exist),
                  :grantee_type => :group,
                  :range        => WIDE_OPEN,
                }
              end

              authorizations_to_ensure << dsl_group.range_authorizations.map do |range_auth|
                range, cidr, protocol = range_auth
                {
                  :grantor      => group_name_with_vpc(dsl_group.name, cloud.vpc),
                  :grantee      => { :cidr_ip => cidr, :ip_protocol => protocol },
                  :grantee_type => :cidr,
                  :range        => range,
                }
              end
            end
          end
          groups_to_create         = groups_to_create.flatten.uniq.reject { |group| recall? group.to_s }.sort
          authorizations_to_ensure = authorizations_to_ensure.flatten.uniq.sort { |a,b| a[:grantor] <=> b[:grantor] }

          Ironfan.step(cluster_name, "creating security groups", :blue) unless groups_to_create.empty?
          groups_to_create.each do |group|
            if group =~ /\//
              Ironfan.step(group, "  assuming that owner/group pair #{group} already exists", :blue)
            else
              Ironfan.step(group, "  creating #{group} security group", :blue)
              begin
                tokens    = group.to_s.split(':')
                group_id  = tokens.pop
                vpc_id    = tokens.pop
                Ec2.connection.create_security_group(group_id,"Ironfan created group #{group_id}",vpc_id)
              rescue Fog::Compute::AWS::Error => e # InvalidPermission.Duplicate
                Chef::Log.info("ignoring security group error: #{e}")
              end
            end
          end

          # Re-load everything so that we have a @@known list of security groups to manipulate
          load! unless groups_to_create.empty?

          # Now make sure that all required authorizations are present
          Ironfan.step(cluster_name, "ensuring security group permissions", :blue) unless authorizations_to_ensure.empty?
          authorizations_to_ensure.each do |auth|
            grantor_fog = recall(auth[:grantor])
            if :group == auth[:grantee_type]
              if fog_grantee = recall(auth[:grantee])
                options = { :group => fog_grantee.group_id }
              elsif auth[:grantee] =~ /\//
                options = { :group_alias => auth[:grantee] }
              else
                raise "Don't know what to do with authorization grantee #{auth[:grantee]}"
              end
              message = "  ensuring access from #{auth[:grantee]} to #{auth[:grantor]}"
            else
              options = auth[:grantee]
              message = "  ensuring #{auth[:grantee][:ip_protocol]} access from #{auth[:grantee][:cidr_ip]} to #{auth[:range]}"
            end
            Ironfan.step(auth[:grantor], message, :blue)
            safely_authorize(grantor_fog, auth[:range], options)
          end
        end

        def self.group_name_with_vpc(name,vpc_id=nil)
          vpc_id.nil? ? name.to_s : "#{vpc_id}:#{name.to_s}"
        end

        def self.most_appropriate_group_name(group, vpc_id, all_valid_groups)
          all_valid_groups.include?(group_name_with_vpc(group, vpc_id)) ? group_name_with_vpc(group, vpc_id) : group
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
          if options[:group_alias]
            owner, group = options[:group_alias].split(/\//)
            self.patiently(fog_group.name, Fog::Compute::AWS::Error, :ignore => Proc.new { |e| e.message =~ /InvalidPermission\.Duplicate/ }) do
              Ec2.connection.authorize_security_group_ingress(
                'GroupName'                   => fog_group.name,
                'SourceSecurityGroupName'     => group,
                'SourceSecurityGroupOwnerId'  => owner
              )
            end
          elsif options[:ip_protocol]
            self.patiently(fog_group.name, Fog::Compute::AWS::Error, :ignore => Proc.new { |e| e.message =~ /InvalidPermission\.Duplicate/ }) do
              fog_group.authorize_port_range(range,options)
            end
          else
            safely_authorize(fog_group,range,options.merge(:ip_protocol => 'tcp'))
            safely_authorize(fog_group,range,options.merge(:ip_protocol => 'udp'))
            safely_authorize(fog_group,Range.new(-1,-1),options.merge(:ip_protocol => 'icmp')) if(range == WIDE_OPEN)
            return
          end
        end
      end
    end
  end
end
