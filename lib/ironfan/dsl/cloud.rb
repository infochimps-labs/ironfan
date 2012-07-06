# TODO: This should get refactored into subclasses by provider, with a
#   factory for the core that multiplexes out them. Building it EC2-specific
#   for today.
module Ironfan
  module Dsl
    class Cloud < Ironfan::Dsl::Builder
      magic :permanent,                 Whatever,       :default => false
      magic :availability_zones,        Array
      magic :flavor,                    String
      magic :backing,                   String
      magic :image_name,                String
      magic :bootstrap_distro,          String
      magic :chef_client_script,        String
      magic :mount_ephemerals,          Whatever       # TODO: This needs better handling
      collection :security_groups,      Ironfan::Dsl::Ec2::SecurityGroup

    end
  end
end