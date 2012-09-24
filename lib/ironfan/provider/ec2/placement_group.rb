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

        def to_s
          "<%-15s %-12s %-12s>" % [ self.class.handle, '', name ]
        end

        def self.load!(cluster)
          Ironfan.substep(cluster.name, "placement groups")
          result = Ec2.connection.describe_placement_groups
          result.body["placementGroupSet"].each do |group|
            register group unless group.blank?
            Chef::Log.debug("Loaded #{group.inspect}")
          end
        end
      end

    end
  end
end
