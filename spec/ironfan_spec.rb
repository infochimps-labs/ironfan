require 'spec_helper'
require 'ironfan'

describe Ironfan do
  context '.cluster' do
    it 'should auto-vivify the cluster definition' do
      Ironfan.cluster('troop')
      Ironfan.clusters.values.map(&:name).should == ['troop']
    end
    #
    it 'should give the same cluster back for the same name' do
      cl1 = Ironfan.cluster('troop'){ facet(:a) }
      cl2 = Ironfan.cluster('troop'){ facet(:b) }
      cl1.should equal(cl2)
    end
    #
    it 'should eval a given block in context of the cluster' do
      Ironfan.cluster('troop'){ environment :set_in_block }
      Ironfan.cluster('troop').environment.should == :set_in_block
    end
    it 'adopts attribute hash if given' do
      Ironfan.cluster('troop', environment: :set_in_hash)
      Ironfan.cluster('troop').environment.should == :set_in_hash
    end
  end
end
