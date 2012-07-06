module Ironfan
  module Dsl
    class Role < Ironfan::Dsl::Builder
      magic     :override_attributes, Hash, :default => {}
    end
  end
end