module Ironfan
  module Dsl
    class Server < Ironfan::Dsl::Compute
      magic     :name,                 Integer

      def full_name()   "#{underlay.full_name}-#{name}"; end
    end
  end
end