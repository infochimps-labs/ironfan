require 'spec_helper'

require 'ironfan'

describe Ironfan::Dsl::Cluster do
  describe 'run lists' do
    subject do
      Ironfan.cluster 'foo' do
        environment :dev
        
        role :systemwide
        
        facet :bar do
          instances 1
          role :nfs_client, :first
        end
      end
    end
    
    its(:environment) { should eql :dev }
    its(:run_list) { should eql ["role[systemwide]"] }
  end
end
