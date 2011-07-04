module ClusterChef
  #
  # Provides magic methods, defined with has_keys
  #
  # @example
  #   class Mom < ClusterChef::DslObject
  #     has_keys(:college, :combat_boots, :fat, :so_fat)
  #   end
  #
  #   class Person
  #     def momma &block
  #       @momma ||= Mom.new
  #       @momma.configure(&block) if block
  #     end
  #   end
  #
  #   yo = Person.new
  #   yo.mamma.combat_boots :wears
  #   yo.momma do
  #     fat    true
  #     so_fat 'When she sits around the house, she sits *AROUND* the house'
  #   end
  #
  class DslObject
    class_attribute :keys
    self.keys = []

    def initialize attrs={}
      @settings = attrs || Mash.new
    end

    def self.has_keys *key_names
      key_names.map!(&:to_sym)
      self.keys += key_names
      key_names.each do |key|
        define_method(key){|*args| set(key, *args) }
      end
    end

    def set key=nil, val=nil
      @settings[key] = val unless val.nil?
      @settings[key]
    end

    def [] key
      @settings[key]
    end

    def to_hash
      @settings.dup
    end

    def to_s
      "<#{self.class} #{to_hash.inspect}>"
    end

    def merge! hsh
      @settings.merge!(hsh.to_hash)
    end

    def reverse_merge! hsh
      @settings.reverse_merge!(hsh.to_hash)
    end

    def configure hsh={}, &block
      merge!(hsh)
      instance_eval(&block) if block
      self
    end

    # helper method for bombing out of a script
    def die(*args) ClusterChef.die(*args) end
  end
end
