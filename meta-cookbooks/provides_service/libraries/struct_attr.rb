module ClusterChef
  module StructAttr

    #
    # Returns a hash with each key set to its associated value.
    #
    # @example
    #    FooClass = Struct(:a, :b)
    #    foo = FooClass.new(100, 200)
    #    foo.to_hash # => { :a => 100, :b => 200 }
    #
    # @return [Hash] a new Hash instance, with each key set to its associated value.
    #
    def to_mash
      Mash.new.tap do |hsh|
        each_pair do |key, val|
          case
          when val.respond_to?(:to_mash) then hsh[key] = val.to_mash
          when val.respond_to?(:to_hash) then hsh[key] = val.to_hash
          else                                hsh[key] = val
          end
        end
      end
    end
    def to_hash() to_mash.to_hash ; end

    # barf.
    def store_into_node(node, a, b=nil)
      if b then
        node[a] ||= Mash.new
        node[a][b] = self.to_mash
      else
        node[a]    = self.to_mash
      end
    end

    module ClassMethods
      def dsl_attr(name, validation)
        name = name.to_sym
        define_method(name) do |arg|
          set_or_return(name, arg, validation)
        end
      end
    end
    def self.included(base) base.extend(ClassMethods) ; end
  end
end
