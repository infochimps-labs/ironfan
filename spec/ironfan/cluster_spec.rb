require 'spec_helper'

require 'ironfan'

describe Ironfan::Dsl::Cluster do
  subject do
    Ironfan.cluster 'troop' do
      environment :dev

      role :generic

      role :is_last, :last
      role :is_first, :first
    end
  end

  its(:name)        { should eql 'troop' }
  its(:environment) { should eql :dev }

  its(:run_list) { should eql [
    "role[is_first]",
    "role[generic]",
    "role[is_last]"
    ]
  }

  context '.facet' do
    it 'should give the same facet back for the same name' do
      facet_1 = subject.facet(:bob){ instances(1) }
      facet_2 = subject.facet(:bob){ instances(2) }
      facet_1.should == facet_2
      facet_1.should == subject.facet(:bob)
      facet_1.instances.should == 2
    end
  end
end
