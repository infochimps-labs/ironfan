require 'gorillib/model/serialization'
require 'gorillib/serialization/to_wire'
require 'gorillib/hash/deep_merge'

module Gorillib

  # Make a clean deep-copy of the value, via gorillib semantics if 
  #   possible, otherwise via marshalling
  def self.deep_copy(value)
    case
    when ( value.respond_to? :to_wire and value.respond_to? :receive )
      return value.class.receive(value.to_wire)
    else
      return Marshal.load(Marshal.dump(value))
    end
  end

  module Model
    Field.class_eval do
      field :resolver, Symbol, :default => :read_set_or_underlay_attribute
    end
  end

  # The attribute :underlay provides an object (preferably another
  #   Gorillib::Model or the like) that will resolve stacked 
  #   defaults. If fields are declared with a :resolver, it will 
  #   apply that call in preference the default rules (self.field
  #   -> underlay.field -> self.field.default )
  #
  # To provide resolve cleanly without read-write loops destroying 
  #   the separation of concerns, the resolve mechanism has been 
  #   broken from the regular read-write accessors.
  #
  module Resolution
    extend  Gorillib::Concern
    include Gorillib::FancyBuilder
    attr_accessor :underlay

    # Return a fully-resolved copy of this object. All objects
    #   referenced will be clean deep_copies, and will lack the 
    #   :underlay accessor. This is by design, to prevent self-
    #   referential loops (parent->collection->child->owner) 
    #   when deep_coping.
    def resolve
      result = self.class.new
      self.class.fields.each do |field_name, field|
        value = read_from_resolver(field_name)
        result.write_attribute(field_name, value) unless value.nil?
      end
      result
    end

    def deep_resolve(field_name)
      temp = read_set_or_underlay_attribute(field_name)
      return if temp.nil?
      if temp.is_a? Gorillib::Collection
        result = temp.class.new
        temp.each_pair {|k,v| result[k] = resolve_value(v) }
      else
        result = resolve_value(v)
      end
      result
    end
    
    def resolve_value(value)
      return if value.nil?
      return value.resolve if value.respond_to? :resolve
      deep_copy(value)
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
