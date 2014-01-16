module Ironfan
  class Dsl
    class SecurityGroup < Ironfan::Dsl
      field :name,                    String
      field :group_authorized,        Array, :default => []
      field :group_authorized_by,     Array, :default => []
      field :range_authorizations,    Array, :default => []
      
      def authorize_port_range(range, cidr_ip = '0.0.0.0/0', ip_protocol = 'tcp')
        range = (range .. range) if range.is_a?(Integer)
        range_authorizations << [range, cidr_ip, ip_protocol]
        range_authorizations.compact!
        range_authorizations.uniq!
      end

      def authorized_by_group(other_name)
        group_authorized_by << other_name.to_s
        group_authorized_by.compact!
        group_authorized_by.uniq!
      end

      def authorize_group(other_name)
        group_authorized << other_name.to_s
        group_authorized.compact!
        group_authorized.uniq!
      end
    end
  end
end
