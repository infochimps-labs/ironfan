module Ironfan
  module Ec2

    class Connection < Ironfan::Provider::IaasConnection
      def discover!
        discover_machines!
        discover_ebs_volumes!
      # Walk the list of servers, asking each to discover its volumes.
        discover_security_groups!
        discover_key_pairs!
        discover_placement_groups!
      end
      
      def discover_machines!
      end
    end

    class Machine < Ironfan::Provider::Machine
    end

    class EbsVolume < Ironfan::Provider::Resource
    end

    class SecurityGroup < Ironfan::Provider::Resource
    end

    class KeyPair < Ironfan::Provider::Resource
    end

    class PlacementGroup < Ironfan::Provider::Resource
    end

  end
end