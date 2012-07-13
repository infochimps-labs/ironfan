module Ironfan
  module Dsl

    class Server < Ironfan::Dsl::Compute
      def index()       name.to_i;      end

      def display_values(style)
        values = {}
        # style == :minimal
        return values if style == :minimal

        # style == :default
        values["Env"] =         environment
        return values if style == :default

        # style == :expanded
        values["Elastic IP"] =  selected_cloud.public_ip if selected_cloud.public_ip
        values
      end
    end

  end
end