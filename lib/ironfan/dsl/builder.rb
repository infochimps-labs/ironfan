module Gorillib
  module Model
    Field.class_eval do
      field :resolver, Symbol, :default => :read_set_or_underlay_attribute
    end
  end

  # The attribute :underlay provides an object (preferably another
  #   Gorillib::Model or the like) that will respond with defaults. If 
  #   fields are declared with a resolver call, it will apply that 
  #   call in preference to the normal resolver rules (self.field
  #   -> underlay.field -> self.field.default )
  #
  # To provide resolve cleanly without read-write loops destroying 
  #   the separation of concerns, the resolve mechanism has been 
  #   broken from the regular read-write accessors.
  #
  module Resolution
    include Gorillib::FancyBuilder
    attr_accessor :underlay

    def resolve
      result = self.class.new
      self.class.fields.each do |field_name, field|
        value = read_from_resolver(field_name)
        next if value.nil?
        result.write_attribute(field_name, deep_copy(value))
      end
      result
    end

    # Make a clean deep-copy of the value, via gorillib semantics if 
    #   possible, otherwise via marshalling
    def deep_copy(value)
      case
      when ( value.respond_to? :to_wire and value.respond_to? :receive )
        return value.class.receive(value.to_wire)
      else
        return Marshal.load(Marshal.dump(value))
      end
    end

    def merge_resolve(field_name)
      field = self.class.fields[field_name] or return
      result = attribute_default(field) or field.type.new
      result.receive! read_underlay_attribute(field_name) || {}
      result.receive! read_set_attribute(field_name) || {}
      result
    end

    def read_from_resolver(field_name)
      field = self.class.fields[field_name] or return
      self.send(field.resolver, field_name)
    end

    def read_set_attribute(field_name)
      attr_name = "@#{field_name}"
      instance_variable_get(attr_name) if instance_variable_defined?(attr_name)
    end

    def read_underlay_attribute(field_name)
      return if underlay.nil?
      underlay.read_from_resolver(field_name)
    end

    def read_set_or_underlay_attribute(field_name)
      result = read_set_attribute(field_name)
      return result unless result.nil?
      read_underlay_attribute(field_name)
    end

  end
end

module Ironfan
  module Dsl
    #
    # This class is intended as a drop-in replacement for DslObject, using 
    #   Gorillib::Builder setup, instead its half-baked predecessor.
    #
    module Hooks
      def self.ui() Ironfan.ui ; end
      def ui()      Ironfan.ui ; end

      # helper method for turning exceptions into warnings
      def safely(*args, &block) Ironfan.safely(*args, &block) ; end

      def step(desc, *style)
        ui.info("  #{"%-15s" % (name.to_s+":")}\t#{ui.color(desc.to_s, *style)}")
      end
    end

    class Builder
      include Gorillib::FancyBuilder
      include Gorillib::Resolution
      include Ironfan::Dsl::Hooks
    end

  end
end
