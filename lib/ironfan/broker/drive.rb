module Ironfan
  class Broker

    class Drive < Builder
      field :node,              Hash,           :default => {}
      field :disk,              Ironfan::Provider::Resource
      field :volume,            Ironfan::Dsl::Volume

      field :name,              String

      # A drive should include volume attributes in any node references
      def node()
        result = super.stringify_keys
        result.merge! volume.attributes.stringify_keys unless volume.nil?
        result
      end

    end

  end
end
