require 'spec_helper'
require_relative '../spec_helper/dummy_chef'
require 'chef/knife/cluster_diff'

describe Chef::Knife::ClusterDiff do
  before(:each) do
    ironfan_go!
    Ironfan.ui = Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
    (Chef::Config[:ec2_image_info] ||= {}).merge!({
      %w[us-east-1  64-bit  ebs     ironfan-precise  ] =>
      { :image_id => 'ami-29fe7640', :ssh_user => 'bam', :bootstrap_distro => "ubuntu12.04-ironfan", },
    })

    Ironfan.realm(:foo) do
      environment :bif

      cloud(:ec2) do
        flavor 'm1.xlarge'
        image_name 'ironfan-precise'
      end
      
      cluster(:bar) do
        cluster_role.override_attributes(a: 1)
        facet(:baz) do
          instances 3
          role :blah
          facet_role.override_attributes(b: 1)
        end
      end
    end
  end

  it 'should diff every targeted instance' do
    computers = Ironfan.broker.discover!(Ironfan.cluster(:foo_bar))
    computers.to_a.map do |computer|
      manifest = computer.server.to_machine_manifest
      computer.server.should(receive(:to_machine_manifest)).and_return(manifest)
    end
    Chef::Knife::ClusterDiff.mismatches?(computers)
  end
end
                                     
