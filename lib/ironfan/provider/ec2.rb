module Ironfan
  module Provider
    module Ec2
      class Connection < Ironfan::Provider::Connection
        def discover!(cluster)
          # build a list of expected servers from the cluster
          # find all machines matching cluster labels
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