require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require CLUSTER_CHEF_DIR("lib/cluster_chef")
require CLUSTER_CHEF_DIR("lib/cluster_chef/script")

describe ClusterChef::Cluster do
  def load_example(name)
    require(CLUSTER_CHEF_DIR('clusters', "#{name}.rb"))
  end

  def get_cluster name
    load_example(name)
    ClusterChef.cluster(name)
  end

  describe 'discover!' do
    let(:cluster){ get_cluster(:monkeyballs) }

    it 'enumerates chef nodes' do
      cluster.discover!
    end
  end
end

