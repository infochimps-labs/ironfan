module Ironfan
  class Provider
    class Ec2

      class KeyPair < Ironfan::Provider::Resource
      end

      class KeyPairs < Ironfan::Provider::ResourceCollection
        self.item_type =        KeyPair
      end

    end
  end
end