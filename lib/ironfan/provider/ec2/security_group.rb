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
          Ironfan::Provider::Ec2.connection.security_groups.each do |sg|
            self << SecurityGroup.new(:adaptee => sg) unless sg.blank?
          end
        end

        #
        # Manipulation
        #

        #def create!(machines)             end

        #def destroy!(machines)            end

        def save!(machines)
          Ironfan.step(machines.cluster.name, "ensuring security groups are set", :blue)
          dsl_groups = machines.map do |m|
            next unless m.server and m.server.clouds.include?(:ec2) \
              and not m.server.cloud(:ec2).security_groups.empty?
            m.server.cloud(:ec2).security_groups.values
          end.flatten.compact.uniq
          dsl_groups.each do |dsl_group|
            dsl_group.group_authorized_by.each do |other_group|
              next unless fog_group = self[other_group]
              Ironfan.step(dsl_group.name, "  ensuring access to #{other_group}", :blue)
              config = {:group => "#{account_id}:#{dsl_group.name}"}
              begin
                fog_group.authorize_port_range(1..65535, config)
              rescue Fog::Compute::AWS::Error => e      # InvalidPermission.Duplicate
                Chef::Log.debug("ignoring #{e}")
              end
            end

            next unless fog_group = self[dsl_group.name]
            dsl_group.range_authorizations.each do |range_auth|
              range, cidr, protocol = range_auth
              step_message = "  ensuring #{protocol} access from #{cidr} to #{range}"
              Ironfan.step(dsl_group.name, step_message, :blue)
              begin
                options = {:cidr_ip => cidr, :ip_protocol => protocol}
                fog_group.authorize_port_range(range,options)
              rescue Fog::Compute::AWS::Error => e      # InvalidPermission.Duplicate
                Chef::Log.debug("ignoring #{e}")
              end
            end
          end
        end
      end

    end
  end
end