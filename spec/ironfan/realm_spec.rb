require 'spec_helper'

require 'ironfan'

describe Ironfan::Dsl::Realm do
  it 'should create clusters that can be referenced later' do
    x = self
    Ironfan.realm :foo do
      cluster(:bar).should(x.be(cluster(:bar)))
    end
  end

  it 'should create clusters that can be edited later' do
    Ironfan.realm :foo do
      cluster(:baz)
      cluster(:baz){ facet :bif }
    end

    Ironfan.cluster(:foo_baz).facets.to_a.should_not(be_empty)
    Ironfan.cluster(:foo_baz).servers.to_a.first.should_not(be_nil)
  end
end
