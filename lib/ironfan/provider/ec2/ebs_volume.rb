module Ironfan
  class Provider
    class Ec2

      class EbsVolume < Ironfan::Provider::Resource
      end

      class EbsVolumes < Ironfan::Provider::ResourceCollection
        self.item_type =        EbsVolume
      end

    end
  end
end