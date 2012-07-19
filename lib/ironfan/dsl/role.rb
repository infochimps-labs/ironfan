module Ironfan
  module Dsl

    class Role < Ironfan::Dsl::Builder
      magic     :override_attributes, Hash, :default => {}
      magic     :default_attributes,  Hash, :default => {}

      def override_attributes(val=nil)
        return super() if val.nil?
        super(read_attribute(:override_attributes).deep_merge(val))
      end
      def default_attributes(val=nil)
        return super() if val.nil?
        super(read_attribute(:default_attributes).deep_merge(val))
      end
    end

  end
end