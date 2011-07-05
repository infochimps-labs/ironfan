require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require CLUSTER_CHEF_DIR("lib/cluster_chef")

describe ClusterChef::Facet do
  let(:cluster){ ClusterChef.cluster(:gibbon) }
  let(:facet){
    cluster.facet(:namenode) do
      instances 5
    end
  }

  describe 'slicing' do
    it 'has servers' do
      facet.indexes.should == [0, 1, 2, 3, 4]
      facet.valid_indexes.should == [0, 1, 2, 3, 4]
      facet.server(3){ name(:bob) }
      svrs = facet.servers
      svrs.length.should == 5
      svrs.map{|svr| svr.name }.should == ["gibbon-namenode-0", "gibbon-namenode-1", "gibbon-namenode-2", :bob, "gibbon-namenode-4"]
    end

    it 'servers have bogosity if out of range' do
      facet.server(69).should be_bogus
      facet.servers.select(&:bogus?).map(&:facet_index).should == [69]
      facet.indexes.should       == [0, 1, 2, 3, 4, 69]
      facet.valid_indexes.should == [0, 1, 2, 3, 4]
    end

    it 'returns all on nil or "", but [] means none' do
      facet.server(69)
      facet.slice('' ).map(&:facet_index).should == [0, 1, 2, 3, 4, 69]
      facet.slice(nil).map(&:facet_index).should == [0, 1, 2, 3, 4, 69]
      facet.slice([] ).map(&:facet_index).should == []
    end

    it 'slice returns all by default' do
      facet.server(69)
      facet.slice().map(&:facet_index).should == [0, 1, 2, 3, 4, 69]
    end

    it 'with an array returns specified indexes (bogus or not) in sorted order' do
      facet.server(69)
      facet.slice( [3, 1, 0]     ).map(&:facet_index).should == [0, 1, 3]
      facet.slice( [3, 1, 69, 0] ).map(&:facet_index).should == [0, 1, 3, 69]
    end

    it 'with an array does not create new dummy servers' do
      facet.server(69)
      facet.slice( [3, 1, 69, 0, 75, 123] ).map(&:facet_index).should == [0, 1, 3, 69]
      facet.has_server?(75).should be_false
      facet.has_server?(69).should be_true
    end

    it 'with a string, converts to intervals' do
      facet.slice('1'      ).map(&:facet_index).should == [1]
      facet.slice('5'      ).map(&:facet_index).should == []
      facet.slice('1-1'    ).map(&:facet_index).should == [1]
      facet.slice('0-1'    ).map(&:facet_index).should == [0,1]
      facet.slice('0-1,3-4').map(&:facet_index).should == [0,1,3,4]
      facet.slice('0-1,69' ).map(&:facet_index).should == [0,1,69]
      facet.slice('0-2,1-3').map(&:facet_index).should == [0,1,2,3]
      facet.slice('3-1'    ).map(&:facet_index).should == []
      facet.slice('2-5'    ).map(&:facet_index).should == [2,3,4]
      facet.slice(1).map(&:facet_index).should == [1]
    end

  end
end

