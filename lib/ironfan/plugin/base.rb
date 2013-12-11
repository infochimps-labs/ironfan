require 'gorillib/model'
require 'gorillib/builder'
require 'gorillib/string/inflections'
require 'gorillib/metaprogramming/concern'

Gorillib::Model::Field.class_eval do
  field :node_attr, String, default: nil
end

module Ironfan

  module Pluggable
    def add_plugin name, cls
      registry[name] = cls
    end
    def plugin_for name
      registry[name]
    end
    def registry() @registry ||= {}; end
  end

  module Plugin
    class CookbookRequirement
      include Gorillib::Builder

      magic :name, String
      magic :constraint, String

      def <=>(other)
        self.name <=> other.name
      end
    end

    module Base
      extend Gorillib::Concern

      def to_node
        Chef::Node.new.tap do |node|
          self.class.fields.select{|_,x| x.node_attr}.each do |_,x|
            val = send(x.name)
            (keys = x.node_attr.split('.'))[0...-1].inject(node.set) do |hsh,key|
              hsh[key]
            end[keys.last] = val unless val.nil?
          end
        end
      end

      module ClassMethods
        attr_reader :cookbook_reqs
        attr_reader :plugin_name

        def from_node(node = NilCheckDelegate.new(nil))
          new(Hash[
                   fields.select{|_,x| x.node_attr}.map do |_,x|
                     [x.name, (x.node_attr.split('.').inject(node) do |hsh,attr|
                                 if hsh
                                   (val = hsh[attr]).is_a?(Mash) ? val.to_hash : val
                                 end
                               end)]
                   end.reject{|_,v| v.nil?}
                  ])
        end

        def register_with cls, &blk
          (@dest_class = cls).class_eval{ extend Ironfan::Pluggable }
        end

        def template plugin_name_parts, base_class=self, &blk
          plugin_name_parts = [*plugin_name_parts]
          full_name = plugin_name_parts.map(&:to_s).join('_').to_sym
          plugin_name = plugin_name_parts.first.to_sym

          Class.new(base_class, &blk).tap do |plugin_class|
            plugin_class.class_eval{ @plugin_name = plugin_name }

            self.const_set(full_name.to_s.camelize.to_sym, plugin_class)

            @dest_class.class_eval do
              add_plugin(full_name, plugin_class)
              define_method(full_name) do |*args, &blk|
                plugin_class.plugin_hook self, (args.first || {}), plugin_name, full_name, &blk
              end
            end
          end
        end
      end
    end
  end
end
