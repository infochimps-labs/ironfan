require 'spec_helper'

describe Ironfan::Dsl, resolution: true do
  it 'merges collections' do
    dmx = DMX.new do
      mx :x1
      dmx(:dmx) do
        mx :x2
      end
    end

    # This will deep-resolve the dmxs collection, which will
    # merge-resolve the mxs collection.

    dmx.resolve!
    dmx.dmx(:dmx).mxs.keys.map(&:to_s).sort.should == %w[ x1 x2 ]
  end

  it 'deep resolves collections when requested' do
    ddx = DDX.new do
      dx :x1
      ddx(:ddx) do
        dx :x2
      end
    end

    # This will deep-resolve the ddxs collection, which will
    # deep-resolve the dxs collection. Because there is a dxs
    # collection set, this will simply ignore the parent dxs
    # collection.

    ddx.resolve!
    ddx.ddx(:ddx).dxs.keys.map(&:to_s).sort.should == %w[ x2 ]
  end

  it 'deep resolves collections when requested and no default is available' do
    ddx = DDX.new do
      dx :x1
      ddx(:ddx) do
      end
    end

    # This will deep-resolve the ddxs collection, which will
    # deep-resolve the dxs collection. Because there is no dxs
    # collection set,this will pull in the parent dxx collection.

    ddx.resolve!
    ddx.ddx(:ddx).dxs.keys.map(&:to_s).sort.should == %w[ x1 ]
  end

  it 'does not resolve when merging' do
    mdx = MDX.new do
      dx :x1
      mdx(:mdx) do
        dx :x2
      end
    end

    # This will merge the mdxs collection with nothing.

    mdx.resolve!
    mdx.mdx(:mdx).dxs.keys.map(&:to_s).sort.should == %w[ x2 ]
  end

  it 'does not resolve when merging, not even merge resolve' do
    mmx = MMX.new do
      mx :x1
      mmx(:mmx) do
        mx :x2
      end
    end

    # This will merge the mmxs collection with nothing. The mmxs
    # collection will not be resolved, so its mxs collection will not
    # be merged with its parent.

    mmx.resolve!
    mmx.mmx(:mmx).mxs.keys.map(&:to_s).sort.should == %w[ x2 ]
  end

  it 'does not merge when deep-resolving' do
    ddmx = DDMX.new do
      dmx :dmx do
        mx :x1
      end
      ddmx(:ddmx) do
        dmx :dmx do
          mx :x2
        end
      end
    end
    ddmx.resolve!

    # This is surprising behavior, but consistent with Ironfan's
    # interface. Because the dmxs collection on the :ddmx object is
    # deep-resolved rather than merge-resolved, its parent is ignored.

    ddmx.ddmx(:ddmx).dmx(:dmx).mxs.keys.map(&:to_s).sort.should == %w[ x2 ]
  end

  it 'merges collections deeply' do
    dmmx = DMMX.new do
      mmx :mmx do
        mx :x1
      end
      dmmx(:dmmx) do
        mmx :mmx do
          mx :x2
        end
      end
    end
    dmmx.resolve!

    # Deep resolve at the top level causes the dmmxs collection to be
    # resolved. It resolves all of its fields, including the mmx
    # field, which is merge-resolved.

    dmmx.dmmx(:dmmx).mmx(:mmx).mxs.keys.map(&:to_s).sort.should == %w[ x1 x2 ]
  end

  it 'does not merge collections very deeply' do
    dmmmx = DMMMX.new do
      mmmx :mmmx do
        mmx :mmx do
          mx :x1
        end
      end
      dmmmx(:dmmmx) do
        mmmx :mmmx do
          mmx :mmx do
            mx :x2
          end
        end
      end
    end
    dmmmx.resolve!

    # FIXME: Shouldn't this be both x1 and x2? I'm going to place this
    # here to test the interface as it exists now.

    dmmmx.dmmmx(:dmmmx).mmmx(:mmmx).mmx(:mmx).mxs.keys.map(&:to_s).sort.should == %w[ x2 ]
  end

  it 'ignores resolution strategies when merging' do
    dmdx = DMDX.new do
      mdx :mdx do
        dx :x1
      end
      dmdx(:dmdx) do
        mdx :mdx do
          dx :x2
        end
      end
    end
    dmdx.resolve!

    # Deep resolve at the top level causes the dmdxs collection to be
    # resolved. It resolves all of its fields, including the mdx
    # field, which is merge-resolved. Note that resolve! does the rest
    # of the work: the merge_resolve method does not recursively
    # resolve, so the dxs "deep resolve" resolution strategy is
    # ignored.

    dmdx.dmdx(:dmdx).mdx(:mdx).dxs.keys.map(&:to_s).sort.should == %w[ x1 x2 ]
  end

  it 'should not raise exceptions when deep-resolving non-collections' do
    class Kablooey < Ironfan::Dsl
      magic :foo, String, :resolver => :deep_resolve
    end

    Kablooey.new(foo: 'bar').resolve!
  end

  it 'may rely on receive! to do a somewhat deep merge, because it does' do
    a = MX.new do
      mx :one
    end
    b = MX.new do
      mx :two
    end

    a.receive! b
    a.mxs.keys.map(&:to_s).sort.should == %w[ one two ]
  end

  it 'does not rely on receive! to do a very deep merge, because it does not' do
    a = MMX.new do
      mmx :mmx do
        mx :one
      end
    end
    b = MMX.new do
      mmx :mmx do
        mx :two
      end
    end

    a.receive! b
    a.mmx(:mmx).mxs.keys.map(&:to_s).sort.should == %w[ two ]
  end
end
