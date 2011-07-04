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
      facet.all_indexes.should == [0, 1, 2, 3, 4]
      facet.server(3){ name(:bob) }
      svrs = facet.servers
      svrs.length.should == 5
      svrs.map{|svr| svr.name }.should == ["gibbon-namenode-0", "gibbon-namenode-1", "gibbon-namenode-2", :bob, "gibbon-namenode-4"]
    end

    it 'servers have bogosity if out of range' do
      facet.server(69).should be_bogus
      facet.all_servers.select(&:bogus?).map(&:facet_index).should == [69]
      facet.all_indexes.should == [0, 1, 2, 3, 4, 69]
    end

    it 'slice([]) means none' do
      facet.slice([] ).map(&:facet_index).should == []
    end
  end
end

