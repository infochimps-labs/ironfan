module Ironfan
  module Dsl

    class Server < Ironfan::Dsl::Compute
      field      :cluster_name, String
      field      :facet_name,   String

      def initialize(attrs={},&block)
        unless attrs[:owner].nil?
          self.cluster_name =   attrs[:owner].cluster_name
          self.facet_name =     attrs[:owner].name
        end
        super
      end

      def fullname()    "#{cluster_name}-#{facet_name}-#{name}";        end
      def index()       name.to_i;                                      end

      def display_values(style,values={})
        selected_cloud.display_values(style,values)

        return values if style == :minimal

        values["Env"] =         environment
        values
      end
    end

  end
end