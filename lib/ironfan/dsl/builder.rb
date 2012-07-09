module Gorillib
  module Model
    Field.class_eval do
      field :resolution, Whatever
    end
  end

  # The attribute :underlay provides an object (preferably another
  #   Gorillib::Model or the like) that will respond with defaults. If 
  #   fields are declared with a resolution lambda, it will apply that 
  #   lambda in preference to the normal resolution rules (self.field
  #   -> underlay.field -> self.field.default )
  #
  # To provide resolution cleanly without read-write loops destroying 
  #   the separation of concerns, the resolution has been broken from
  #   the regular read-write accessors.
  #
  module Resolution
    include Gorillib::FancyBuilder
    attr_accessor :underlay

    def resolve
      result = underlay.resolve || this.class.new
      current = to_wire
      self.class.fields.each_pair do |field_name,field|
        # resolve its values using chosen resolution
        # set the resulting field 
      end
    end

#     def read_attribute(field_name)
#       field = self.class.fields[field_name] or return
#       result = read_from_resolution(field_name)
#       return result unless result.to_s.empty?
#       read_unset_attribute(field_name)
#     end

    def merge_resolve(field_name)
      result = self.class.fields[field_name].type.new
      result.receive! read_underlay_attribute(field_name) || {}
      result.receive! read_set_attribute(field_name) || {}
    end

    def read_from_resolution(field_name)
      field = self.class.fields[field_name] or return
      resolution = field.resolution || ->(f){ read_set_or_underlay_attribute(f) }
      instance_exec(field_name, &resolution)
    end

    def read_set_attribute(field_name)
      attr_name = "@#{field_name}"
      instance_variable_get(attr_name) if instance_variable_defined?(attr_name)
    end

    def read_underlay_attribute(field_name)
      return if underlay.nil?
      result = underlay.read_from_resolution(field_name)
      return if result.nil?
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

    class BuilderCollection < Gorillib::ModelCollection
      include Ironfan::Dsl::Hooks
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
end
