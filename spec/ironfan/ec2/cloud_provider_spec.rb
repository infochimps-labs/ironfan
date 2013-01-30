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
        cloud(:ec2) do
          flavor 'm1.small'
          mount_ephemerals({ :disks => { 0 => { :mount_point => '/data' } } })
        end
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

    it 'should have its first ephemeral disk mounted at /data' do
      @facet.servers[0].implied_volumes[1].mount_point.should == '/data'
    end
  end

end
