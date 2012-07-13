module Ironfan
  module Dsl

    class Server < Ironfan::Dsl::Compute
      def index()       name.to_i;      end

      def display_values(style,values={})
        selected_cloud.display_values(style,values)

        return values if style == :minimal

        values["Env"] =         environment
        values
      end
    end

  end
end