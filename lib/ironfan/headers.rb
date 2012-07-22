# This file sets up the base class structure before any of it is
#   loaded, to allow parts to declare relationships to each other
#   without regard to declaration order. No active code should
#   be present in this file.
module Gorillib
  module Resolution
  end
end

module Ironfan
  module Dsl
    module Hooks; end
    class Builder
      include Gorillib::FancyBuilder
      include Gorillib::Resolution
      include Ironfan::Dsl::Hooks
    end

    class Compute < Ironfan::Dsl::Builder; end
    class Cluster < Ironfan::Dsl::Compute; end
    class Facet < Ironfan::Dsl::Compute; end
    class Server < Ironfan::Dsl::Compute; end

    class Role < Ironfan::Dsl::Builder; end
    class Volume < Ironfan::Dsl::Builder; end

    class Cloud < Ironfan::Dsl::Builder; end
    class Ec2 < Cloud
      class SecurityGroup < Ironfan::Dsl::Builder; end
    end
    class VirtualBox < Cloud; end
  end

  class Broker
    class Machine; end
    class MachineCollection < Gorillib::ModelCollection; end
  end

  class Provider
    include Gorillib::Builder
    class Resource
      include Gorillib::Builder
    end
  end
  class IaasProvider < Provider
    class Instance < Resource; end
  end

  class Provider
    class ChefServer < Ironfan::Provider
      class Client < Ironfan::Provider::Resource; end
      class Node < Ironfan::Provider::Resource; end
      class Role < Ironfan::Provider::Resource; end
    end

    class Ec2 < Ironfan::IaasProvider
      class Instance < Ironfan::IaasProvider::Instance; end
      class EbsVolume < Ironfan::Provider::Resource; end
      class SecurityGroup < Ironfan::Provider::Resource; end
      class KeyPair < Ironfan::Provider::Resource; end
      class PlacementGroup < Ironfan::Provider::Resource; end
    end

    class VirtualBox < Ironfan::IaasProvider
      class Instance < Ironfan::IaasProvider::Instance; end
    end
  end

end
