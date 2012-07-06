module Ironfan
  module Dsl
    class Server < Ironfan::Dsl::Compute
      field      :name,         Integer
      magic      :facet,        Whatever

    end
  end
end