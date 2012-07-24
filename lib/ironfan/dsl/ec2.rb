module Ironfan
  class Dsl

    class Ec2 < Cloud
      magic :permanent,               :boolean,       :default => false
      magic :availability_zones,      Array
      magic :flavor,                  String
      magic :backing,                 String
      magic :image_name,              String
      magic :bootstrap_distro,        String
      magic :chef_client_script,      String
      magic :mount_ephemerals,        Whatever       # TODO: This needs better handling
      collection :security_groups,    Ironfan::Dsl::Ec2::SecurityGroup
      magic :public_ip,               String

      def to_display(style,values={})
        return values if style == :minimal

        values["Flavor"] =            flavor
        values["AZ"] =                availability_zones.first unless availability_zones.nil?
        return values if style == :default

        values["Elastic IP"] =        public_ip if public_ip
        values
      end

      class SecurityGroup < Ironfan::Dsl
        field :name,                    String
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