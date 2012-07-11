module Ironfan
  module Ec2

    class Connection < Ironfan::Provider::IaasConnection
      def discover!(cluster)
        discover_machines! cluster
        #discover_ebs_volumes!
          # Walk the list of servers, asking each to discover its volumes.
        #discover_security_groups!
        #discover_key_pairs!
        #discover_placement_groups!
      end
      
      def discover_machines!(cluster)
        return machines unless machines.empty?
        # @fog_servers ||= Ironfan.fog_servers.select{|fs| fs.key_name == cluster_name.to_s && (fs.state != "terminated") }
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