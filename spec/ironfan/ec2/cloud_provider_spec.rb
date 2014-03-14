require 'spec_helper'

describe Ironfan::Dsl::Cluster do
  let(:cluster) do
    Ironfan.cluster 'sparky' do

      cloud(:ec2) do
        security_group(:ssh).authorize_port_range(22..22)
        flavor 't1.micro'
      end

      facet :web do
        instances 3
        cloud(:ec2) do
          flavor 'm1.small'
          mount_ephemerals(disks: { 0 => { mount_point: '/data' } })
        end
      end      
    end

    Ironfan.cluster('sparky').resolve
  end

  context 'web facet server resolution' do
    subject(:facet){ cluster.facets.values.first }

    its(:name){ should eq('web') }

    it 'has the right number of servers' do
      facet.servers.length.should eq(3)
    end

    it 'has one cloud provider, EC2' do
      facet.servers[0].clouds.keys.should eq([:ec2])
    end

    it 'has its first ephemeral disk mounted at /data' do
      facet.servers[0].implied_volumes[1].mount_point.should eq('/data')
    end
  end

end
