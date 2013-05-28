module Ironfan
  class Provider
    class Rds

      class SecurityGroup < Ironfan::Provider::Resource

        delegate :id, :authorize_port_range,
          :to => :adaptee

        def self.shared?()      true;   end
        def self.multiple?()    true;   end
        def self.resource_type()        :security_group;   end
        def self.expected_ids(computer)
          return unless computer.server
          rds = computer.server.cloud(:rds)
          rds.security_groups.keys.uniq
        end

        def name()
          adaptee.id
        end

        #
        # Discovery
        #
        def self.load!(cluster=nil)
          Rds.connection.security_groups.reject { |raw| raw.blank? }.each do |raw|
            sg = SecurityGroup.new(:adaptee => raw)
            remember(sg)
            Chef::Log.debug("Loaded #{sg}: #{sg.inspect}")
          end
        end

        def receive_adaptee(obj)
          obj = Rds.connection.security_groups.new(obj) if obj.is_a?(Hash)
          super
        end

        def to_s
            return "<%-15s %s>" % [ self.class.handle, id ]
        end

        #
        # Manipulation
        #

        def self.prepare!(computers)

          # Create any groups that don't yet exist, and ensure any authorizations
          # that are required for those groups
          cluster_name             = nil
          groups_to_create         = [ ]
          ec2_authorizations       = [ ]
          ip_authorizations        = [ ]

          # First, deduce the list of all groups to which at least one instance belongs
          # We'll use this later to decide whether to create groups, or authorize access,
          # using a VPC security group or an EC2 security group.

          computers.select { |computer| Rds.applicable computer }.each do |computer|
            cloud           = computer.server.cloud(:rds)
            cluster_name    = computer.server.cluster_name

            # Iterate over all of the security group information, keeping track of
            # any groups that must exist and any authorizations that must be ensured
            cloud.security_groups.values.each do |dsl_group|
              groups_to_create << dsl_group.name
              ip_authorizations << dsl_group.ip_authorizations.map do |ip|
                { 
                  :grantor => dsl_group.name, 
                  :grantee => ip,
                }
              end

              ec2_authorizations << dsl_group.ec2_authorizations.map do |ec2|
                {
                  :grantor => dsl_group.name, 
                  :grantee => ec2,
                }
              end
            end
          end

          groups_to_create   = groups_to_create.flatten.uniq.reject { |group| recall? group.to_s }.sort
          ip_authorizations  = ip_authorizations.flatten.uniq.sort { |a,b| a[:grantor] <=> b[:grantor] }
          ec2_authorizations = ec2_authorizations.flatten.uniq.sort { |a,b| a[:grantor] <=> b[:grantor] }

          Ironfan.step(cluster_name, "creating security groups", :blue) unless groups_to_create.empty?
          groups_to_create.each do |group|
            Ironfan.step(group, "creating #{group} security group", :blue)
            begin
              Rds.connection.create_db_security_group(group,"Ironfan created group #{group}")
            rescue Fog::Compute::AWS::Error => e # InvalidPermission.Duplicate
              Chef::Log.info("ignoring security group error: #{e}")
            end
          end

          # Re-load everything so that we have a @@known list of security groups to manipulate
          load! unless groups_to_create.empty?

          # Now make sure that all required authorizations are present
          Ironfan.step(cluster_name, "ensuring security group permissions", :blue) unless (ec2_authorizations.empty? or ip_authorizations.empty?)
          ip_authorizations.each do |auth|
            message = " ensuring access from #{auth[:grantor]} to #{auth[:grantee]} "
            Ironfan.step(auth[:grantor], message, :blue)
            begin 
              Rds.connection.authorize_db_security_group_ingress(auth[:grantor], { "CIDRIP" => auth[:grantee] })
            rescue Fog::AWS::RDS::AuthorizationAlreadyExists => e
              Chef::Log.info("ignoring security group error: #{e}")
            end
          end

          ec2_authorizations.each do |auth|
            message = " ensuring access from #{auth[:grantor]} to #{auth[:grantee]} "
            Ironfan.step(auth[:grantor], message, :blue)
            aws_account, security_group = auth[:grantee].split('/')
            begin 
              Rds.connection.authorize_db_security_group_ingress(auth[:grantor], { "EC2SecurityGroupName" => security_group, "EC2SecurityGroupOwnerId" => aws_account })
            rescue Fog::AWS::RDS::AuthorizationAlreadyExists => e
              Chef::Log.info("ignoring security group error: #{e}")
            end
          end

        end
      end
    end
  end
end
