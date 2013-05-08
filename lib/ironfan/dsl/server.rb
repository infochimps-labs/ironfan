module Ironfan
  class Dsl

    class Server < Ironfan::Dsl::Compute
      field      :cluster_name, String
      field      :facet_name,   String

      def initialize(attrs={},&block)
        unless attrs[:owner].nil?
          self.cluster_name =   attrs[:owner].cluster_name
          self.facet_name =     attrs[:owner].name

          self.role     "#{self.cluster_name}-cluster", :last
          self.role     attrs[:owner].facet_role.name,  :last
        end
        super
      end

      def full_name()           "#{cluster_name}-#{facet_name}-#{name}";        end
      def index()               name.to_i;                                      end
      def implied_volumes()     selected_cloud.implied_volumes;                 end

      def to_display(style,values={})
        selected_cloud.to_display(style,values)

        return values if style == :minimal

        values["Env"] =         environment
        values
      end

      # we should always show up in owners' inspect string
      def inspect_compact ; inspect ; end

      # @returns [Hash{String, Array}] of 'what you did wrong' => [relevant, info]
      def lint
        errors = []
        errors['missing cluster/facet/server'] = [cluster_name, facet_name, name] unless (cluster_name && facet_name && name)
        errors
      end
    end

  end
end
