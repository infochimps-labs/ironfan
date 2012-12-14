require_relative '../spec_helper'

Ironfan.cluster "simple" do

  cloud(:ec2) do
    availability_zones ('b'..'d').map { |z| "us-east-1#{z}" }
    flavor              't1.micro'
    backing             'ebs'
    image_name          'alestic-precise'
    chef_client_script  'client.rb'
    security_group      :systemwide
    security_group      :ssh do
      authorize_port_range(22..22)
    end
    mount_ephemerals
  end

  facet :web do
    instances 1
    cloud(:ec2).security_group(:web) do
      authorize_group :web_clients
      authorize_group 'amazon-elb/amazon-elb-sg'
    end
  end

  facet :db do
    instances 1
  end
end


launch_cluster 'simple' do |cluster, computers|
  describe "the simple cluster" do

    it "should have the correct number of running computers" do
      computers.size.should == cluster.facets.keys.inject(0) { |size, facet| size + cluster.facets[facet].instances }
      computers.values.reject { |c| c.running? }.should be_empty
    end

    describe "the web facet security groups" do
      subject { cluster.facets[:web].server(0).cloud(:ec2).security_groups.keys.map(&:to_s).sort }
      it { should == %w[ simple simple-web ssh systemwide web ] }
    end

    describe "the db facet security groups" do
      subject { cluster.facets[:db].server(0).cloud(:ec2).security_groups.keys.map(&:to_s).sort }
      it { should == %w[ simple simple-db ssh systemwide ] }
    end

    describe "the passively created security groups" do
      it "should include the :web_clients group" do
        Ironfan::Provider::Ec2::SecurityGroup.recall('web_clients').should_not be_nil
      end
    end

    describe "the cluster-wide security group" do
      before :each do
        @sg = Ironfan::Provider::Ec2::SecurityGroup.recall('simple')
        @ordered_ipp = Hash[ @sg.ip_permissions.map { |s| [ s['ipProtocol'], s ] } ]
      end

      it "has the right number of inbound security rules" do
        @ordered_ipp.keys.size == 3
      end

      it "allows TCP connections on all ports between all servers in the security group" do
        @ordered_ipp['tcp']['groups'].size.should                == 1
        @ordered_ipp['tcp']['groups'][0]['groupId'].should       == @sg.group_id
        @ordered_ipp['tcp']['groups'][0]['groupName'].should     == 'simple'
        @ordered_ipp['tcp']['fromPort'].to_i.should              == 1
        @ordered_ipp['tcp']['toPort'].to_i.should                == 65535
      end

      it "allows UDP connections on all ports between all servers in the security group" do
        @ordered_ipp['udp']['groups'].size.should                == 1
        @ordered_ipp['udp']['groups'][0]['groupId'].should       == @sg.group_id
        @ordered_ipp['udp']['groups'][0]['groupName'].should     == 'simple'
        @ordered_ipp['udp']['fromPort'].to_i.should              == 1
        @ordered_ipp['udp']['toPort'].to_i.should                == 65535
      end

      it "allows ICMP connections between all servers in the security group" do
        @ordered_ipp['icmp']['groups'].size.should                == 1
        @ordered_ipp['icmp']['groups'][0]['groupId'].should       == @sg.group_id
        @ordered_ipp['icmp']['groups'][0]['groupName'].should     == 'simple'
        @ordered_ipp['icmp']['fromPort'].to_i.should              == -1
        @ordered_ipp['icmp']['toPort'].to_i.should                == -1
      end
    end

    describe "the web security group" do
      before :each do
        @sg = Ironfan::Provider::Ec2::SecurityGroup.recall('web')
        @ordered_ipp = Hash[ @sg.ip_permissions.map { |s| [ s['ipProtocol'], s ] } ]
      end

      it "allows TCP connections to web_clients and to amazon-elb-sg" do
        @ordered_ipp['tcp']['groups'].map { |g| g['groupName'] }.sort.should == %w[ amazon-elb-sg web_clients ]
      end
    end
  end
end
