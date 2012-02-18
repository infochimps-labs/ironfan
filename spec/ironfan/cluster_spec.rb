require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require IRONFAN_DIR("lib/ironfan")

describe Ironfan::Cluster do
  describe 'discover!' do
    let(:cluster){ get_example_cluster(:monkeyballs) }

    it 'enumerates chef nodes' do
      cluster.discover!
    end
  end
end
