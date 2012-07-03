module Gorillib
  module Model
    Field.class_eval do
      field :resolution, Whatever
    end
  end
  module Underlies
    include Gorillib::FancyBuilder

    magic :underlay, Whatever

    def override_resolve(field_name)
      result = read_set_attribute(field_name)
      return result unless result.nil?
      result = read_underlay_attribute(field_name)
      return result unless result.nil?
      read_unset_attribute(field_name)
    end

    def merge_resolve(field_name)
      result = self.class.fields[field_name].type.new
      d = read_unset_attribute(field_name) and result.receive!(d)
      u = read_underlay_attribute(field_name) and result.receive!(u)
      s = read_set_attribute(field_name) and result.receive!(s)
      result
    end

    def read_attribute(field_name)
      field = self.class.fields[field_name] or return
      return override_resolve(field_name) unless field.resolution.is_a? Proc
      return self.instance_exec(field_name, &field.resolution)
    end

    def read_set_attribute(field_name)
      attr_name = "@#{field_name}"
      instance_variable_get(attr_name) if instance_variable_defined?(attr_name)
    end

    def read_underlay_attribute(field_name)
      return if field_name == :underlay
      underlay.read_attribute(field_name) unless @underlay.nil?
    end

    def read_unset_attribute(field_name)
      field = self.class.fields[field_name]
      return unless field.has_default?
      attribute_default(field)
    end

  end
end

module Ironfan
  #
  # This class is intended as a drop-in replacement for DslObject, using 
  #   Gorillib::Builder setup, instead its half-baked predecessor.
  #
  # The magic attribute :underlay provides an object (preferably another
  #   Gorillib::Model or the like) that will respond with defaults. If 
  #   fields are declared with a resolution lambda, it will apply that 
  #   lambda in preference to the normal resolution rules (self.field
  #   -> underlay.magic -> self.field.default )
  #
  module DslHooks
    def self.ui() Ironfan.ui ; end
    def ui()      Ironfan.ui ; end

    # helper method for turning exceptions into warnings
    def safely(*args, &block) Ironfan.safely(*args, &block) ; end

    def step(desc, *style)
      ui.info("  #{"%-15s" % (name.to_s+":")}\t#{ui.color(desc.to_s, *style)}")
    end
  end

  class DslBuilder
    include Gorillib::FancyBuilder
    include Gorillib::Underlies
    include Ironfan::DslHooks
  end

  class DslBuilderCollection < Gorillib::ModelCollection
    include Ironfan::DslHooks
    include Enumerable
#     #
#     # Enumerable
#     #
#     def each(&block)
#       @servers.each(&block)
#     end
#     def length
#       @servers.length
#     end
#     def empty?
#       length == 0
#     end
  end
end
