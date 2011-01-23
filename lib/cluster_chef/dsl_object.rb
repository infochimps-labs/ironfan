module ClusterChef
  class DslObject
    def initialize
      @settings = Hash.new{|h,k| h[k] = {} }
    end

    def set key=nil, val=nil
      @settings[key] = val unless val.nil?
      @settings[key]
    end

    def method_missing meth, *args
      set meth, *args
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
