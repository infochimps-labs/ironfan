# This file sets up the base class structure before any of it is
#   loaded, to allow parts to declare relationships to each other
#   without regard to declaration order. No active code should
#   be present in this file.
module Ironfan

  class Builder
    include Gorillib::Builder
  end

  class Broker < Builder
    class Computer < Builder; end
    class Computers < Gorillib::ModelCollection; end
    class Drive < Builder; end
  end

  class Dsl < Builder
    class Component < Ironfan::Dsl; end
    class Compute < Ironfan::Dsl; end
    class Cluster < Ironfan::Dsl::Compute; end
    class Facet < Ironfan::Dsl::Compute; end
    class Realm < Ironfan::Dsl::Compute; end
    class Server < Ironfan::Dsl::Compute; end

    class Role < Ironfan::Dsl; end
    class Volume < Ironfan::Dsl; end

    class Cloud < Ironfan::Dsl; end
    class Ec2 < Cloud
      class SecurityGroup < Ironfan::Dsl; end
      class ElasticLoadBalancer < Ironfan::Dsl; end
      class IamServerCertificate < Ironfan::Dsl; end
    end
    class VirtualBox < Cloud; end
    class Vsphere < Cloud; end
    class Rds < Cloud
      class SecurityGroup < Ironfan::Dsl; end
    end
  end

  module Plugin
    class CookbookRequirement; end
  end

  class Provider < Builder
    class Resource < Builder; end
  end
  class IaasProvider < Provider
    class Machine < Resource; end
  end
  class Provider
    class ChefServer < Ironfan::Provider
      class Client < Ironfan::Provider::Resource; end
      class Node < Ironfan::Provider::Resource; end
      class Role < Ironfan::Provider::Resource; end
    end
    class Ec2 < Ironfan::IaasProvider
      class EbsVolume < Ironfan::Provider::Resource; end
      class ElasticIp < Ironfan::Provider::Resource; end
      class Machine < Ironfan::IaasProvider::Machine; end
      class Keypair < Ironfan::Provider::Resource; end
      class PlacementGroup < Ironfan::Provider::Resource; end
      class SecurityGroup < Ironfan::Provider::Resource; end
      class ElasticLoadBalancer < Ironfan::Provider::Resource; end
      class IamServerCertificate < Ironfan::Provider::Resource; end
    end
    class VirtualBox < Ironfan::IaasProvider
      class Machine < Ironfan::IaasProvider::Machine; end
    end
    class Vsphere < Ironfan::IaasProvider
      class Machine < Ironfan::IaasProvider::Machine; end
      class Keypair < Ironfan::Provider::Resource; end
    end
    class Rds < Ironfan::IaasProvider
      class Machine < Ironfan::IaasProvider::Machine; end
      class SecurityGroup < Ironfan::Provider::Resource; end
    end
  end

end
