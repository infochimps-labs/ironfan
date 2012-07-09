module Ironfan
  module Dsl
    module Ec2
      class SecurityGroup < Ironfan::Dsl::Builder
        field :group_authorized_by,     Array, :default => []
        field :range_authorizations,    Array, :default => []

        def authorize_port_range(range, cidr_ip = '0.0.0.0/0', ip_protocol = 'tcp')
          range = (range .. range) if range.is_a?(Integer)
          range_authorizations << [range, cidr_ip, ip_protocol]
        end

        def authorized_by_group(other_name)
          group_authorized_by << other_name.to_s
        end
      end
    end
  end
end