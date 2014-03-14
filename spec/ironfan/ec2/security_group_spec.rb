require 'spec_helper'

describe Ironfan::Dsl::Cluster do
  let(:cluster) do
    Ironfan.cluster 'quirky' do

      cloud(:ec2) do
        security_group(:ssh).authorize_port_range(22..22)
        flavor 't1.micro'
      end

      facet :web do
        cloud(:ec2).security_group('quirky-web').authorize_port_range(80)
        cloud(:ec2).flavor 'm1.small'
      end

      facet :mysql do
        # My what a permissive database you have.
        cloud(:ec2).security_group('quirky-mysql').authorize_port_range(3306)
        cloud(:ec2).flavor 'm1.xlarge'
      end
    end

    Ironfan.cluster('quirky').resolve
  end

  context 'cluster definition' do
    subject{ cluster }

    its(:name)       { should eq('quirky')  }
    its(:environment){ should eq(:_default) }
    its(:run_list)   { should eq([])        }

    context 'facets' do
      let(:facets){ cluster.facets }

      subject{ facets.values }

      its(:length){ should eq(2) }

      context 'web facet' do
        subject(:facet){ facets.values.first }

        its(:name){ should eq('web') }

        it 'has the correct flavor' do
          facet.cloud(:ec2).flavor.should eq('m1.small')
        end

        it 'has the right number of servers' do
          facet.servers.length.should eq(1)
        end

        context 'security groups' do
          subject(:groups){ facet.clouds.values.first.security_groups.values }

          its(:length){ should eq(2) }

          it 'authorizes ssh on port 22 from anywhere' do
            ssh_auth = groups.detect{ |g| g.name == 'ssh' }
            ssh_auth.should_not be_nil
            ssh_auth.range_authorizations.should include([22..22, '0.0.0.0/0', 'tcp'])
          end

          it 'authorizes HTTP on port 80 from anywhere' do
            http_auth = groups.detect{ |g| g.name == 'quirky-web' }
            http_auth.should_not be_nil
            http_auth.range_authorizations.should include([80..80, '0.0.0.0/0', 'tcp'])
          end

        end
      end

      context 'mysql facet' do
        subject(:facet){ facets.values.last }

        its(:name){ should eq('mysql') }

        it 'has the correct flavor' do
          facet.cloud(:ec2).flavor.should eq('m1.xlarge')
        end

        context 'security groups' do
          subject(:groups){ facet.clouds.values.first.security_groups.values }

          its(:length){ should eq(2) }

          it 'authorizes ssh on port 22 from anywhere' do
            groups.one?{ |g| g.name == 'ssh' }.should be_true
          end

          it 'authorizes MySQL on port 3306 from anywhere' do
            mysql_auth = groups.detect{ |g| g.name == 'quirky-mysql' }
            mysql_auth.should_not be_nil
            mysql_auth.range_authorizations.should include([3306..3306, '0.0.0.0/0', 'tcp'])
          end

        end
      end
    end
  end
end
