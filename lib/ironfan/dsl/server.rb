module Ironfan
  class Dsl

    # class MachineManifest
    #   include Gorillib::Model

    #   field :components, Array, of: Ironfan::Dsl::Component
    #   field :environment, String
    #   field :run_list, Array, of: String
    #   field :cluster_default_attributes, Hash
    #   field :cluster_override_attributes, Hash
    #   field :facet_default_attributes, Hash
    #   field :facet_override_attributes, Hash
    #   field :volumes, Array, of: Volume
    #   field :cloud, Ironfan::Dsl::Cloud
    # end

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


      def canonical_machine_manifest_hash
        canonicalize(
                     run_list: run_list,
                     components: components,
                     cluster_default_attributes: cluster_role.default_attributes,
                     cluster_override_attributes: cluster_role.override_attributes,
                     facet_default_attributes: facet_role.default_attributes,
                     facet_override_attributes: facet_role.override_attributes,
                     volumes: volumes,
                     cloud: clouds.each.to_a.first,
                     )
        # MachineManifest.new({
        #                       run_list: run_list,
        #                       flavor:   cloud.flavor,
        #                       ...
        #                     })
      end

      private

      def canonicalize(item)
        case item
        when Array, Gorillib::ModelCollection
          item.each.map{|i| canonicalize(i)}
        when Ironfan::Dsl::Component
          canonicalize(item.to_manifest)
        when Gorillib::Builder
          canonicalize(item.to_wire.tap{|x| x.delete(:_type)})
        when Hash then
          Hash[item.sort.map{|k,v| [k, canonicalize(v)]}]
        else
          item
        end
      end
    end

  end
end
