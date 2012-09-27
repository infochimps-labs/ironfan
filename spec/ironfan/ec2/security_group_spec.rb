require 'spec_helper'

require 'ironfan'

describe Ironfan::Dsl::Cluster do
  let (:cluster) do
    Ironfan.cluster "sparky" do
      cloud(:ec2).security_group(:ssh).authorize_port_range 22..22
      facet :web do
        cloud(:ec2).security_group("sparky-web").authorize_port_range(80)
      end
    end
  end
    
  describe 'cluster definition' do
    subject { cluster }
    
    its(:name) { should eql "sparky" }
    its(:environment) { should eql :_default }
    its(:run_list) { should eql [] }
    
    describe 'facets' do
      before { @facets = cluster.facets }
      subject { @facets.values }
      its(:length) { should eql 1 }
      
      describe 'web facet' do
        before { @facet = @facets.values.first }
        subject { @facet }
        its(:name) { should eql "web" }
        
        describe 'security groups' do
          before { @groups = @facet.clouds.values.first.security_groups.values }
          subject { @groups }
          
          its(:length) { should eql 2 }
          
          it 'authorizes ssh on port 22 from anywhere' do
            ssh_auth = @groups.first
            ssh_auth.range_authorizations.first.should eql [22..22, "0.0.0.0/0", "tcp"]
          end
          
          it 'authorizes HTTP on port 80 from anywhere' do
            http_auth = @groups.last
            http_auth.range_authorizations.first.should eql [80..80, "0.0.0.0/0", "tcp"]
          end
        end
      end
      
    end
    
    describe 'clouds' do
      
    end
  end
end

