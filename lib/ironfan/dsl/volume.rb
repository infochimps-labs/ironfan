module Ironfan
  module Dsl
    class Volume < Ironfan::Dsl::Builder
      magic     :volume_id,     String
      magic     :device,        String
      magic     :mount_point,   String
    end
  end
end