require_relative '../spec_helper'

Ironfan.cluster "elb" do

  cloud(:ec2) do
    availability_zones ('b'..'d').map { |z| "us-east-1#{z}" }
    flavor              't1.micro'
    backing             'ebs'
    image_name          'alestic-precise'
    chef_client_script  'client.rb'
    iam_server_certificate "snake-oil" do
      certificate IO.read(File.expand_path('../../../fixtures/ec2/elb/snakeoil.crt', __FILE__))
      private_key IO.read(File.expand_path('../../../fixtures/ec2/elb/snakeoil.key', __FILE__))
    end
    security_group      :systemwide
    security_group      :ssh do
      authorize_port_range(22..22)
    end
    mount_ephemerals
  end

  facet :web do
    instances 2
    cloud(:ec2) do

      elastic_load_balancer "simple-elb" do
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


launch_cluster 'elb' do |cluster, computers|
  describe "the elb cluster" do

    it "should have the correct number of running computers"
    # it "should have the correct number of running computers" do
    #   computers.size.should == cluster.facets[:web].instances
    #   computers.values.reject { |c| c.running? }.should be_empty
    # end

    describe "the snake-oil certificate" do
      before :each do
        @iss = Ironfan::Provider::Ec2::IamServerCertificate.recall('ironfan-elb-snake-oil')
      end

      it "should exist"
      # it "should exist" do
      #   @iss.should_not be_nil
      # end

      it "should be retrievable by ARN"
      # it "should be retrievable by ARN" do
      #   @iss.should == Ironfan::Provider::Ec2::IamServerCertificate.recall("#{Ironfan::Provider::Ec2::IamServerCertificate::ARN_PREFIX}:#{@iss['Arn']}")
      # end

    end

    describe "the ELB" do
      before :each do
        @elb = Ironfan::Provider::Ec2::ElasticLoadBalancer.recall('ironfan-elb-simple-elb')
      end

      it "should exist"
      # it "should exist" do
      #   @elb.should_not be_nil
      # end

      it "should have two instances"
      #   @elb.instances.size.should == cluster.facets[:web].instances
      # end

      it "should use the snake-oil certificate"
      # it "should use the snake-oil certificate" do
      #   iss = Ironfan::Provider::Ec2::IamServerCertificate.recall('ironfan-elb-snake-oil')
      #   @elb.listeners.map(&:ssl_id).include?(iss['Arn']).should be_true
      # end
    end

  end
end
