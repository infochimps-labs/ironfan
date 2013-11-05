require 'spec_helper'

require 'ironfan'

describe Ironfan::Dsl::Realm do
  it 'should create clusters that can be referenced later' do
    x = self
    Ironfan.realm :foo do
      cluster(:bar).should(x.be(cluster(:bar)))
    end
  end

  it 'should create clusters that can be edited later' do
    Ironfan.realm :foo do
      cluster(:baz)
      cluster(:baz){ facet :bif }
    end

    Ironfan.cluster(:foo_baz).facets.to_a.should_not(be_empty)
    Ironfan.cluster(:foo_baz).servers.to_a.first.should_not(be_nil)
  end

  it 'should create clusters with names prefixed by its own' do
    Ironfan.realm(:foo){ cluster(:bar) }
    Ironfan.cluster(:foo_bar).should_not(be_nil)
  end

  it 'should create clusters with machines' do
    Ironfan.realm(:foo){ cluster(:bar) }
    Ironfan.cluster(:foo_bar).should_not(be_nil)
  end

  it 'should create clusters with the correct ssh user' do
    (Chef::Config[:ec2_image_info] ||= {}).merge!({
      %w[us-east-1  64-bit  ebs     ironfan-precise  ] =>
      { :image_id => 'ami-29fe7640', :ssh_user => 'bam', :bootstrap_distro => "ubuntu12.04-ironfan", },
    })
    Ironfan.realm(:foo) do
      cloud(:ec2) do
        flavor 'm1.xlarge'
        image_name 'ironfan-precise'
      end
      cluster(:bar){ facet(:baz) }
    end
    cloud = Ironfan.cluster(:foo_bar).facets[:baz].servers.to_a.first.cloud(:ec2)
    cloud.flavor.should == 'm1.xlarge'
    cloud.ssh_user.should == 'bam'
  end

  it 'should save cloud properties to be shared among all clusters within the realm' do
    Ironfan.realm :foo do
      cloud(:ec2).flavor 'm1.xlarge'
      cluster(:bar){ facet(:baz) }
    end

    # We need to resolve before the cloud settings come through
    Ironfan.realm(:foo).clusters[:foo_bar].resolve.facets[:baz].cloud(:ec2).flavor.should == 'm1.xlarge'

    # Ironfan.cluster will do the resolution for us.
    Ironfan.cluster(:foo_bar).facets[:baz].cloud(:ec2).flavor.should == 'm1.xlarge'
  end

  it 'should save an environment to be shared among all clusters within the realm' do
    Ironfan.realm :foo do
      environment :bif
      cluster(:bar){ facet(:baz) }
    end

    # We need to resolve before the cloud settings come through
    Ironfan.realm(:foo).clusters[:foo_bar].resolve.facets[:baz].environment.should == :bif

    # Ironfan.cluster will do the resolution for us.
    Ironfan.cluster(:foo_bar).facets[:baz].environment.should == :bif
  end
  
end
