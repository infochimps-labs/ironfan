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
        cloud(:ec2).security_group("sparky-web").authorize_port_range(80)
        cloud(:ec2).flavor 'm1.small'
      end

      facet :mysql do
        # My what a permissive database you have.
        cloud(:ec2).security_group("sparky-mysql").authorize_port_range(3306)
        cloud(:ec2).flavor 'm1.xlarge'
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
      its(:length) { should eql 2 }

      describe 'web facet' do
        before { @facet = @facets.values.first }
        subject { @facet }
        its(:name) { should eql "web" }

        it 'should have the correct flavor' do
          @facet.cloud(:ec2).flavor.should  == 'm1.small'
        end

        it 'should have the right number of servers' do
          @facet.servers.length.should == 1
        end

        describe 'security groups' do
          before { @groups = @facet.clouds.values.first.security_groups.values }
          subject { @groups }

          its(:length) { should eql 2 }

          it 'authorizes ssh on port 22 from anywhere' do
            ssh_auth = @groups.detect { |g| g.name == 'ssh' }
            ssh_auth.should_not be_nil
            ssh_auth.range_authorizations.select { |g| g.eql? [22..22, "0.0.0.0/0", "tcp"] }.should_not be_empty
          end

          it 'authorizes HTTP on port 80 from anywhere' do
            http_auth = @groups.detect { |g| g.name == 'sparky-web' }
            http_auth.should_not be_nil
            http_auth.range_authorizations.select { |g| g.eql? [80..80, "0.0.0.0/0", "tcp"] }.should_not be_empty
          end

        end
      end

      describe 'mysql facet' do
        before { @facet = @facets.values.last }
        subject { @facet }
        its(:name) { should eql "mysql" }

        it 'should have the correct flavor' do
          @facet.cloud(:ec2).flavor.should  == 'm1.xlarge'
        end

        describe 'security groups' do
          before { @groups = @facet.clouds.values.first.security_groups.values }
          subject { @groups }

          its(:length) { should eql 2 }

          it 'authorizes ssh on port 22 from anywhere' do
            ssh_auth = @groups.detect { |g| g.name == 'ssh' }
            ssh_auth.should_not be_nil
          end

          it 'authorizes MySQL on port 3306 from anywhere' do
            mysql_auth = @groups.detect { |g| g.name == 'sparky-mysql' }
            mysql_auth.should_not be_nil
            mysql_auth.range_authorizations.select { |g| g.eql? [3306..3306, "0.0.0.0/0", "tcp"] }.should_not be_empty
          end

        end
      end
    end
  end
end
