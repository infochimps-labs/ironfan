# This file sets up the base class structure before any of it is
#   loaded, to allow parts to declare relationships to each other
#   without regard to declaration order. No active code should
#   be present in this file.
module Ironfan

  class Builder
    include Gorillib::Builder
  end

  class Broker < Builder
    class Machine < Builder; end
    class Machines < Gorillib::ModelCollection; end
  end

  class Dsl < Builder
    class Compute < Ironfan::Dsl; end
    class Cluster < Ironfan::Dsl::Compute; end
    class Facet < Ironfan::Dsl::Compute; end
    class Server < Ironfan::Dsl::Compute; end

    class Role < Ironfan::Dsl; end
    class Volume < Ironfan::Dsl; end

    class Cloud < Ironfan::Dsl; end
    class Ec2 < Cloud
      class SecurityGroup < Ironfan::Dsl; end
    end
    class VirtualBox < Cloud; end
  end

  class Provider < Builder
    class Resource < Builder; end
    class ResourceCollection < Gorillib::ModelCollection; end
  end
  class IaasProvider < Provider
    class Instance < Resource; end
  end
  class Provider
    class ChefServer < Ironfan::Provider
      class Client < Ironfan::Provider::Resource; end
      class Clients < Ironfan::Provider::ResourceCollection; end
      class Node < Ironfan::Provider::Resource; end
      class Nodes < Ironfan::Provider::ResourceCollection; end
      class Role < Ironfan::Provider::Resource; end
      class Roles < Ironfan::Provider::ResourceCollection; end
    end
    class Ec2 < Ironfan::IaasProvider
      class EbsVolume < Ironfan::Provider::Resource; end
      class EbsVolumes < Ironfan::Provider::ResourceCollection; end
      class ElasticIp < Ironfan::Provider::Resource; end
      class ElasticIps < Ironfan::Provider::ResourceCollection; end
      class Instance < Ironfan::IaasProvider::Instance; end
      class Instances < Ironfan::Provider::ResourceCollection; end
      class KeyPair < Ironfan::Provider::Resource; end
      class KeyPairs < Ironfan::Provider::ResourceCollection; end
      class PlacementGroup < Ironfan::Provider::Resource; end
      class PlacementGroups < Ironfan::Provider::ResourceCollection; end
      class SecurityGroup < Ironfan::Provider::Resource; end
      class SecurityGroups < Ironfan::Provider::ResourceCollection; end
    end
    class VirtualBox < Ironfan::IaasProvider
      class Instance < Ironfan::IaasProvider::Instance; end
    end
  end

end








cluster launch
#   broker.discover cluster, :all => true
#     machines = broker.expected_machines cluster
#     [chef,ec2].load! machines
#       [clients,nodes].each.load! machines
#       [instances,ebs_volumes].each.load! machines
#     [chef,ec2].correlate! machines
#       [clients,nodes].each.correlate! machines
#       [instances,ebs_volumes].each.correlate! machines
#     [chef,ec2].validate! machines
#       nodes.validate! machines
#       ebs_volumes.validate! machines
#   broker.sync! machines
    [chef,ec2].save! machines
      nodes.save! machines
      [instances, ebsvolumes, security_groups].each.save! machines
#   broker.create_dependencies! machines
    [chef,ec2].create_dependencies! machines
      clients.create! machines
      [ebsvolumes, security_groups,key_pairs].each.save! machines
#   broker.create_instances! machines
    chef.create_instances! machines
      nodes.create! machines
    ec2.create_instances! machines
#       instances.create! machines
  broker.save! machines
    [chef,ec2].save! machines
      nodes.save! machines
      [instances, ebsvolumes, security_groups].each.save! machines
