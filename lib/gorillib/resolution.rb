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

    # Modifies the Gorillib metaprogramming to handle deep recursion on
    # Gorillib::Model collections which would prefer to handle arbitrarily
    # complex resolution requirements via their (custom) receive! method
    module ClassMethods
      def define_collection_receiver(field)
       collection_field_name = field.name; collection_type = field.type
        # @param  [Array[Object],Hash[Object]] the collection to merge
        # @return [Gorillib::Collection] the updated collection
        define_meta_module_method("receive_#{collection_field_name}", true) do |coll, &block|
          begin
            existing = read_attribute(collection_field_name)
            if existing and (not collection_type.native?(coll) or existing.respond_to?(:receive!))
              existing.receive!(coll, &block)
            else
              write_attribute(collection_field_name, coll)
            end
          rescue StandardError => err ; err.polish("#{self.class} #{collection_field_name} collection on #{coll}'") rescue nil ; raise ; end
        end
      end
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
        value = read_resolved_attribute(field_name)
        result.write_attribute(field_name, value) unless value.nil?
      end
      result
    end

    def resolve!
      resolved = resolve
      self.class.fields.each do |field_name, field|
        write_attribute(field_name, resolved.send(field_name.to_sym))
      end
      self
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
      result = field.type.new
      merge_values(result,read_underlay_attribute(field_name))
      merge_values(result,read_set_attribute(field_name))
      result
    end

    def merge_values(target, value=nil)
      value ||= {}
      if target.is_a? Gorillib::Collection
        value.each_pair do |k,v|
          existing = target[k]
          if existing && existing.respond_to?(:receive!)
            target[k].receive! v
          elsif existing && existing.respond_to?(:merge!)
            target[k].merge! v
          else
            target[k] = v
          end
        end
      else
        target.receive! value
      end
    end

    def read_resolved_attribute(field_name)
      field = self.class.fields[field_name] or return
      self.send(field.resolver, field_name)
    end

    def read_set_attribute(field_name)
      attr_name = "@#{field_name}"
      instance_variable_get(attr_name) if instance_variable_defined?(attr_name)
    end

    def read_underlay_attribute(field_name)
      return if underlay.nil?
      Gorillib.deep_copy(underlay.read_resolved_attribute(field_name))
    end

    def read_set_or_underlay_attribute(field_name)
      result = read_set_attribute(field_name)
      return result unless result.nil?
      read_underlay_attribute(field_name)
    end
  end

end
