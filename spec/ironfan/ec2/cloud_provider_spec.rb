require 'spec_helper'

require 'ironfan'

describe Ironfan::Dsl::Cluster do
  let (:cluster) do
    Ironfan.cluster "sparky" do

      cloud(:ec2) do
        security_group(:ssh).authorize_port_range 22..22
        flavor 't1.micro'
      end

      facet :web do
        instances 3
      end

    end
  end

  describe 'web facet server resolution' do
    before { @facet = cluster.facets.values.first }
    subject { @facet }
    its(:name) { should eql "web" }

    it 'should have the right number of servers' do
      @facet.servers.length.should == 3
    end

    it 'should have one cloud provider, EC2' do
      @facet.servers[0].clouds.keys.should == [ :ec2 ]
    end
  end

end
