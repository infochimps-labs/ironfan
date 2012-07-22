module Ironfan
  class Provider
    class Ec2

      class PlacementGroup < Ironfan::Provider::Resource
      end

      class PlacementGroups < Ironfan::Provider::ResourceCollection
        self.item_type =        PlacementGroup
      end

    end
  end
end