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
      end

      class SecurityGroups < Ironfan::Provider::ResourceCollection
        self.item_type =        SecurityGroup
        attr_accessor           :account_id

        def load!(cluster)
          self.account_id = Chef::Config[:knife][:aws_account_id]
          Ec2.connection.security_groups.each do |sg|
            self << SecurityGroup.new(:adaptee => sg) unless sg.blank?
          end
        end

        #
        # Manipulation
        #

        def create!(machines)
          ensure_groups(machines)

          groups = Ec2.applicable(machines).map do |machine|
            machine.server.cloud(:ec2).security_groups.keys
          end.flatten.compact.uniq
          # Only handle groups that don't already exist
          groups.delete_if {|g| not self[g.to_s].nil? }
          return if groups.empty?

          Ironfan.step(machines.cluster.name, "creating security groups", :blue)
          groups.each do |group|
            Ironfan.step(group, "  creating #{group} security group", :blue)
            Ec2.connection.create_security_group(group.to_s,"Ironfan created group #{group}")
          end
          load!(machines.cluster)
        end

        #def destroy!(machines)            end

        def save!(machines)
          create!(machines)     # Make sure the security groups exist
          dsl_groups = Ec2.applicable(machines).map do |m|
            next if m.server.cloud(:ec2).security_groups.empty?
            m.server.cloud(:ec2).security_groups.values.select do |g|
              not (g.range_authorizations.empty? and g.group_authorized_by.empty?)
            end
          end.flatten.compact.uniq

          Ironfan.step(machines.cluster.name, "ensuring security group permissions", :blue)
          dsl_groups.each do |dsl_group|
            dsl_group.group_authorized_by.each do |other_group|
              next unless fog_group = self[other_group]
              Ironfan.step(dsl_group.name, "  ensuring access to #{other_group}", :blue)
              options = {:group => "#{account_id}:#{dsl_group.name}"}
              safely_authorize(fog_group,1..65535,options)
              safely_authorize(fog_group,1..65535,options.merge(:ip_protocol => 'udp'))
            end

            next unless fog_group = self[dsl_group.name]
            dsl_group.range_authorizations.each do |range_auth|
              range, cidr, protocol = range_auth
              step_message = "  ensuring #{protocol} access from #{cidr} to #{range}"
              Ironfan.step(dsl_group.name, step_message, :blue)
              options = {:cidr_ip => cidr, :ip_protocol => protocol}
              safely_authorize(fog_group,range,options)
              safely_authorize(fog_group,range,options.merge(:ip_protocol => 'udp'))
            end
          end
        end

        #
        # Utility
        #
        def ensure_groups(machines)
          # Ensure the security_groups include those for cluster & facet
          # FIXME: This violates the DSL's immutability; it should be
          #   something calculated from within the DSL construction
          Ec2.applicable(machines).each do |m|
            cloud = m.server.cloud(:ec2)
            c_group = cloud.security_group(m.server.cluster_name)
            c_group.authorized_by_group(c_group.name)
            facet_name = "#{m.server.cluster_name}-#{m.server.facet_name}"
            cloud.security_group(facet_name)
          end
        end

        # Try an authorization, ignoring duplicates (this is easier than correlating)
        def safely_authorize(fog_group,range,options)
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