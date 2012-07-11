module Ironfan
  module Provider
    module Ec2
      class Connection < Ironfan::Provider::Connection
        def discover!
          discover_machines!
          discover_ebs_volumes!
        # Walk the list of servers, asking each to discover its volumes.
          discover_security_groups!
          discover_key_pairs!
          discover_placement_groups!
        end
      end

      class Machine < Ironfan::Provider::Machine
      end

      class EbsVolume
      end

      class SecurityGroup
      end

      class KeyPair
      end

      class PlacementGroup
      end
    end
  end
end