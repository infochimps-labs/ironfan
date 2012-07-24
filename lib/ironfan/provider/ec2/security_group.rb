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

        def load!(cluster)
          Ironfan::Provider::Ec2.connection.security_groups.each do |sg|
            self << SecurityGroup.new(:adaptee => sg) unless sg.blank?
          end
        end

        #
        # Manipulation
        #

        #def create!(machines)             end

        #def destroy!(machines)            end

        #def save!(machines)               end
      end

    end
  end
end