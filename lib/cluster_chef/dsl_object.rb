require 'cluster_chef/core_ext/class'

module ClusterChef
  class DslObject
    class_attribute :keys
    self.keys = []
    def self.has_keys *k
      self.keys += k
    end

    def initialize
      @settings = Hash.new          # {|h,k| h[k] = {} }
    end

    def set key=nil, val=nil
      @settings[key] = val unless val.nil?
      @settings[key]
    end

    def method_missing meth, *args
      if self.class.keys.include?(meth)
        set meth, *args
      else
        super
      end
    end

    def [] key
      @settings[key]
    end

    def to_hash
      @settings.dup
    end

    def to_s
      to_hash.to_s
    end

  end
end
