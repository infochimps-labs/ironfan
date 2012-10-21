require 'spec_helper'

require 'ironfan'

cert  = IO.read(File.realpath(File.join(File.dirname(__FILE__), '../../fixtures/ec2/elb/snakeoil.crt')))
key   = IO.read(File.realpath(File.join(File.dirname(__FILE__), '../../fixtures/ec2/elb/snakeoil.key')))

describe Ironfan::Dsl::Cluster do
  let (:cluster) do

    Ironfan.cluster "sparky" do

      cloud(:ec2) do
        iam_server_certificate "snake-oil" do
          certificate cert
          private_key key
        end
      end

      facet :web do
        instances 2
        cloud(:ec2) do

          elastic_load_balancer "sparky-elb" do
            map_port('HTTP',   80, 'HTTP', 81)
            map_port('HTTPS', 443, 'HTTP', 81, 'snake-oil')
            disallowed_ciphers %w[ RC4-SHA ]

            health_check do
              ping_protocol       'HTTP'
              ping_port           82
              ping_path           '/healthcheck'
              timeout             4
              interval            10
              unhealthy_threshold 3
              healthy_threshold   2
            end
          end

        end
      end
    end
  end

  describe 'cluster definition' do
    subject { cluster }

    its(:name) { should eql "sparky" }
    its(:environment) { should eql :_default }
    its(:run_list) { should eql [] }

    it "should have one IAM server certificate" do
      cluster.clouds.values.first.iam_server_certificates.values.length.should == 1
    end

    describe 'facets' do
      before { @facets = cluster.facets }
      subject { @facets.values }
      its(:length) { should eql 1 }

      describe 'web facet' do
        before { @facet = @facets.values.first }
        subject { @facet }
        its(:name) { should eql "web" }
        describe "elastic load balancers" do

          before { @elb = @facet.clouds.values.first.elastic_load_balancers.values.first }
          subject { @elb }
          its(:name) { should eql "sparky-elb" }

          it "should have two port mappings" do
            @elb.port_mappings.length.should == 2
          end

          it "should have just one disallowed SSL cipher" do
            @elb.disallowed_ciphers.length.should == 1
          end

          describe "health check" do
            before { @hc = @elb.health_check }
            subject { @hc }
            its(:ping_protocol) { should eql 'HTTP' }
            its(:ping_port) { should eql 82 }
            its(:ping_path) { should eql '/healthcheck' }
            its(:timeout) { should eql 4 }
            its(:interval) { should eql 10 }
            its(:unhealthy_threshold) { should eql 3 }
            its(:healthy_threshold) { should eql 2 }
          end

        end
      end
    end
  end
end
