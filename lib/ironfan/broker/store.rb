module Ironfan
  class Broker

    class Store < Builder
      field :node,              Hash,           :default => {}
      field :disk,              Ironfan::Provider::Resource
      field :volume,            Ironfan::Dsl::Volume

      field :name,              String

      def volume=(value)
        super
        return unless value
        # inscribe the cluster DSL values into chef attributes
        volume.attributes.each_pair {|k,v| node[k.to_s] = v }
      end

    end

    class Stores < Gorillib::ModelCollection
      self.item_type    = Store
      self.key_method   = :name

    end

  end
end