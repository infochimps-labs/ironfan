module Ironfan
  module Dsl
    module Cloud
      class Base < Ironfan::Dsl::Builder
        magic :default_cloud,           :boolean,       :default => false

        # Factory out to subclasses 
        def self.receive(obj,&block)
          klass = case obj[:name]
            when :ec2;            Ec2
            when :virtualbox;     VirtualBox
            else;         raise "Unsupported cloud #{obj[:name]}"
            end
          klass.new(obj,&block)
        end
      end

      class Ec2 < Base
        magic :permanent,               Whatever,       :default => false
        magic :availability_zones,      Array
        magic :flavor,                  String
        magic :backing,                 String
        magic :image_name,              String
        magic :bootstrap_distro,        String
        magic :chef_client_script,      String
        magic :mount_ephemerals,        Whatever       # TODO: This needs better handling
        collection :security_groups,    Ironfan::Dsl::Ec2::SecurityGroup
        magic :public_ip,               String

        def display_values(style,values={})
          return values if style == :minimal

          values["Flavor"] =            flavor
          values["AZ"] =                availability_zones.first unless availability_zones.nil?
          return values if style == :default

          values["Elastic IP"] =        public_ip if public_ip
          values
        end
      end

      class VirtualBox < Base
      end

    end
  end
end