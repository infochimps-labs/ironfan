module Ironfan
  class Provider
    class Ec2

      class SecurityGroup < Ironfan::Provider::Resource
      end

      class SecurityGroups < Ironfan::Provider::ResourceCollection
        self.item_type =        SecurityGroup
      end

    end
  end
end