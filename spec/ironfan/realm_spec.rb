require 'spec_helper'

require 'ironfan'

describe Ironfan::Dsl::Realm do
  it 'should create clusters that can be referenced later' do
    x = self
    Ironfan.realm :foo do
      cluster(:bar).should(x.be(cluster(:bar)))
    end
  end
end
