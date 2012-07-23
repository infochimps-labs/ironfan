module Ironfan
  class Provider
    class Ec2

      # Fog::AWS doesn't seem to have native models for PlacementGroup,
      #   using Hash semantics instead
      class PlacementGroup < Ironfan::Provider::Resource
        delegate :[],:[]=,      :to => :adaptee

        def name()
          self["groupName"]
        end
      end

      class PlacementGroups < Ironfan::Provider::ResourceCollection
        self.item_type =        PlacementGroup

        def discover!(cluster)
          result = Ironfan::Provider::Ec2.connection.describe_placement_groups
          result.body["placementGroupSet"].each do |pg|
            self << PlacementGroup.new(:adaptee => pg) unless pg.blank?
          end
        end

        def correlate!(cluster,machines)
        end

        def sync!(machines)
          raise 'unimplemented'
        end
      end

    end
  end
end