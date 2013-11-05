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
    Ironfan.realm(:foo){ cluster(:bar){ facet(:baz).instances 1 }}
    Ironfan.cluster(:foo_bar).facets[:baz].server(0).should_not(be_nil)
  end

  it 'should create clusters with attributes correctly applied' do
    (Chef::Config[:ec2_image_info] ||= {}).merge!({
      %w[us-east-1  64-bit  ebs     ironfan-precise  ] =>
      { :image_id => 'ami-29fe7640', :ssh_user => 'bam', :bootstrap_distro => "ubuntu12.04-ironfan", },
    })
    Ironfan.realm(:foo) do
      cloud(:ec2) do
        flavor 'm1.xlarge'
        image_name 'ironfan-precise'
      end
        
      cluster(:bar) do
        cluster_role.override_attributes(a: 1)
        facet(:baz) do
          instances 1
          role :blah
          facet_role.override_attributes(b: 1)
        end
      end
    end
    manifest = Ironfan.cluster(:foo_bar).facets[:baz].server(0).to_machine_manifest
    manifest.cluster_override_attributes.should == {a: 1}
    manifest.facet_override_attributes.should == {b: 1}
    manifest.run_list.should == %w[role[blah] role[foo_bar-cluster] role[foo_bar-baz-facet]]
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
    manifest = Ironfan.cluster(:foo_bar).facets[:baz].servers.to_a.first.to_machine_manifest
    manifest.flavor.should == 'm1.xlarge'
    manifest.ssh_user.should == 'bam'
  end

  it 'should save cloud properties to be shared among all clusters within the realm' do
    (Chef::Config[:ec2_image_info] ||= {}).merge!({
      %w[us-east-1  64-bit  ebs     ironfan-precise  ] =>
      { :image_id => 'ami-29fe7640', :ssh_user => 'bam', :bootstrap_distro => "ubuntu12.04-ironfan", },
    })
    Ironfan.realm :foo do
      cloud(:ec2) do
        flavor 'm1.xlarge'
        image_name 'ironfan-precise'
      end        
      cluster(:bar){ facet(:baz) }
    end

    # We need to resolve before the cloud settings come through
    Ironfan.realm(:foo).clusters[:foo_bar].resolve.facets[:baz].servers.to_a.first.to_machine_manifest.flavor.should == 'm1.xlarge'

    # Ironfan.cluster will do the resolution for us.
    Ironfan.cluster(:foo_bar).facets[:baz].servers.to_a.first.to_machine_manifest.flavor.should == 'm1.xlarge'
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
