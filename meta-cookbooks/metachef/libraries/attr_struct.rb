module ClusterChef
  module AttrStruct
    include Chef::Mixin::ParamsValidate

    module ClassMethods
      def keys() [] ; end
      def keys=(val)
        singleton_class = class << self ; self ; end
        singleton_class.class_eval do
          remove_method(:keys) rescue NameError
          define_method(:keys){ val }
        end
        val
      end

      def dsl_attr(name, validation={})
        name   = name.to_sym
        coerce      = validation.delete(:coerce)
        dup_default = validation.delete(:dup_default)
        validation.delete(:doc)
        define_method(name) do |val=nil|
          validation[:default] = dup_default.dup unless dup_default.nil?
          val = val.send(coerce) if val && coerce
          set_or_return(name, val, validation)
        end
        self.keys |= [name]
      end
    end
    def self.included(base) base.extend(ClassMethods) ; end

    def initialize(*args)
      raise ArgumentError, "wrong number of arguments (#{args.length} for #{self.class.keys.length})" if args.length > self.class.keys.length
      args.zip(self.class.keys).each do |val, attr|
        self.send(attr, val)
      end
    end

    def keys
      self.class.keys
    end
    def []=(attr, val)
      self.send(attr, val) if has_key?(attr)
    end

    def each_pair
      self.class.keys.each do |attr|
        yield [attr, self.send(attr)]
      end
    end
    def has_key?(key)
      keys.include?(key.to_sym)
    end
    def ==(val)
      val.is_a?(self.class) && (val.to_hash == self.to_hash)
    end

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

    #
    # Adds the contents of +other_hash+ to +hsh+.  If no block is
    # specified, entries with duplicate keys are overwritten with the values from
    # +other_hash+, otherwise the value of each duplicate key is determined by
    # calling the block with the key, its value in +hsh+ and its value in
    # +other_hash+.
    #
    # @example
    #     h1 = { :a => 100, :b => 200 }
    #     h2 = { :b => 254, :c => 300 }
    #     h1.merge!(h2)
    #     # => { :a => 100, :b => 254, :c => 300 }
    #
    #     h1 = { :a => 100, :b => 200 }
    #     h2 = { :b => 254, :c => 300 }
    #     h1.merge!(h2){|key, v1, v2| v1 }
    #     # => { :a => 100, :b => 200, :c => 300 }
    #
    # @overload hsh.update(other_hash)                               -> hsh
    #   Adds the contents of +other_hash+ to +hsh+.  Entries with duplicate keys are
    #   overwritten with the values from +other_hash+
    #   @param  other_hash [Hash, AttrStruct] the hash to merge (it wins)
    #   @return [AttrStruct] this attr_struct, updated
    #
    # @overload hsh.update(other_hash){|key, oldval, newval| block}  -> hsh
    #   Adds the contents of +other_hash+ to +hsh+.  The value of each duplicate key
    #   is determined by calling the block with the key, its value in +hsh+ and its
    #   value in +other_hash+.
    #   @param  other_hash [Hash, AttrStruct] the hash to merge (it wins)
    #   @yield  [Object, Object, Object] called if key exists in each +hsh+
    #   @return [AttrStruct] this attr_struct, updated
    #
    def update(other_hash)
      raise TypeError, "can't convert #{other_hash.nil? ? 'nil' : other_hash.class} into Hash" unless other_hash.respond_to?(:each_pair)
      other_hash.each_pair do |key, val|
        next unless keys.include?(key.to_sym)
        if block_given? && has_key?(key)
          val = yield(key, val, self.send(key))
        end
        self[key] = val
      end
      self
    end
    alias_method :merge!, :update

    #
    # Returns a new attr_struct containing the contents of +other_hash+ and the
    # contents of +hsh+. If no block is specified, the value for entries with
    # duplicate keys will be that of +other_hash+. Otherwise the value for each
    # duplicate key is determined by calling the block with the key, its value in
    # +hsh+ and its value in +other_hash+.
    #
    # @example
    #     h1 = { :a => 100, :b => 200 }
    #     h2 = { :b => 254, :c => 300 }
    #     h1.merge(h2)
    #     # => { :a=>100, :b=>254, :c=>300 }
    #     h1.merge(h2){|key, oldval, newval| newval - oldval}
    #     # => { :a => 100, :b => 54,  :c => 300 }
    #     h1
    #     # => { :a => 100, :b => 200 }
    #
    # @overload hsh.merge(other_hash)                               -> hsh
    #   Adds the contents of +other_hash+ to +hsh+.  Entries with duplicate keys are
    #   overwritten with the values from +other_hash+
    #   @param  other_hash [Hash, AttrStruct] the hash to merge (it wins)
    #   @return [AttrStruct] a new merged attr_struct
    #
    # @overload hsh.merge(other_hash){|key, oldval, newval| block}  -> hsh
    #   Adds the contents of +other_hash+ to +hsh+.  The value of each duplicate key
    #   is determined by calling the block with the key, its value in +hsh+ and its
    #   value in +other_hash+.
    #   @param  other_hash [Hash, AttrStruct] the hash to merge (it wins)
    #   @yield  [Object, Object, Object] called if key exists in each +hsh+
    #   @return [AttrStruct] a new merged attr_struct
    #
    def merge(*args, &block)
      self.dup.update(*args, &block)
    end
  end
end
