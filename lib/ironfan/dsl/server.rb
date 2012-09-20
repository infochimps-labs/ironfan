module Ironfan
  class Dsl

    class Server < Ironfan::Dsl::Compute
      field      :cluster_name, String
      field      :facet_name,   String

      def initialize(attrs={},&block)
        unless attrs[:owner].nil?
          self.cluster_name =   attrs[:owner].cluster_name
          self.facet_name =     attrs[:owner].name

          self.role     "#{self.cluster_name}_cluster", :last
          self.role     attrs[:owner].facet_role.name,  :last
        end
        super
      end

      def fullname()            "#{cluster_name}-#{facet_name}-#{name}";        end
      def index()               name.to_i;                                      end
      def implied_volumes()     selected_cloud.implied_volumes;                 end

      def to_display(style,values={})
        selected_cloud.to_display(style,values)

        return values if style == :minimal

        values["Env"] =         environment
        values
      end
    end

  end
end