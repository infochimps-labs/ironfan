shared_context :resolution, resolution: true do
  module ResolutionHelpers
    def initialize(attrs = {}, &blk)
      self.underlay = attrs.delete(:owner)
      super(attrs, &blk)
    end
  end

  class X < Ironfan::Dsl
    include ResolutionHelpers
    magic :name, Symbol
    magic :dat, Integer
  end

  class MSym < Ironfan::Dsl
    include ResolutionHelpers
    magic :name, Symbol, :resolver => :merge_resolve, key_method: :name
  end

  class MX < X
    collection :mxs, X, :resolver => :merge_resolve, key_method: :name
  end

  class DX < X
    collection :dxs, X, :resolver => :deep_resolve, key_method: :name
  end

  class DMX < MX
    collection :dmxs, MX, :resolver => :deep_resolve, key_method: :name
  end

  class DDX < DX
    collection :ddxs, DX, :resolver => :deep_resolve, key_method: :name
  end

  class MDX < DX
    collection :mdxs, DX, :resolver => :merge_resolve, key_method: :name
  end

  class MMX < MX
    collection :mmxs, MX, :resolver => :merge_resolve, key_method: :name
  end

  class DDMX < DMX
    collection :ddmxs, DMX, :resolver => :deep_resolve, key_method: :name
  end

  class DMMX < MMX
    collection :dmmxs, MMX, :resolver => :deep_resolve, key_method: :name
  end

  class MMMX < MMX
    collection :mmmxs, MMX, :resolver => :merge_resolve, key_method: :name
  end

  class DMDX < MDX
    collection :dmdxs, MDX, :resolver => :deep_resolve, key_method: :name
  end

  class DMMMX < MMMX
    collection :dmmmxs, MMMX, :resolver => :deep_resolve, key_method: :name
  end
end
