require 'spec_helper'

cert = File.read Pathname.path_to(:fixtures).join('ec2/elb/snakeoil.crt').to_s
key  = File.read Pathname.path_to(:fixtures).join('ec2/elb/snakeoil.key').to_s

describe Ironfan::Dsl::Cluster do
  let(:cluster) do

    Ironfan.cluster 'sparky' do

      cloud(:ec2) do
        iam_server_certificate 'snake-oil' do
          certificate cert
          private_key key
        end
      end

      facet :web do
        instances 2
        cloud(:ec2) do

          elastic_load_balancer 'sparky-elb' do
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

    Ironfan.cluster('sparky').resolve
  end

  context 'cluster definition' do
    subject{ cluster }

    its(:name)       { should eq('sparky')  }
    its(:environment){ should eq(:_default) }
    its(:run_list)   { should eq([])        }

    it 'has one IAM server certificate' do
      cluster.clouds.values.first.iam_server_certificates.values.length.should eq(1)
    end

    context 'facets' do
      let(:facets){ cluster.facets }

      subject{ facets.values }

      its(:length){ should eq(1) }

      context 'web facet' do
        subject(:facet){ facets.values.first }

        its(:name){ should eq('web') }

        context 'elastic load balancer' do

          subject(:elb){ facet.clouds.values.first.elastic_load_balancers.values.first }

          its(:name){ should eq('sparky-elb') }

          it 'has two port mappings' do
            elb.port_mappings.length.should eq(2)
          end

          it 'has just one disallowed SSL cipher' do
            elb.disallowed_ciphers.length.should eq(1)
          end

          context 'health check' do
            subject(:health_check){ elb.health_check }

            its(:ping_protocol)      { should eq('HTTP')         }
            its(:ping_port)          { should eq(82)             }
            its(:ping_path)          { should eq('/healthcheck') }
            its(:timeout)            { should eq(4)              }
            its(:interval)           { should eq(10)             }
            its(:unhealthy_threshold){ should eq(3)              }
            its(:healthy_threshold)  { should eq(2)              }
          end

        end
      end
    end
  end
end
