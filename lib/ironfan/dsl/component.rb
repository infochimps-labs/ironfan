module Ironfan
  class Dsl
    class Component < Ironfan::Dsl
      include Gorillib::Builder

      def to_manifest
        to_wire.reject{|k,_| _skip_fields.include? k}
      end

      def _skip_fields() skip_fields << :_type; end

      def skip_fields() [] end
    end
  end
end
