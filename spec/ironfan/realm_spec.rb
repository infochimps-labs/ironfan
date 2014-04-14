require 'spec_helper'

describe Ironfan::Dsl::Realm do  
  before(:each) do
    (Chef::Config[:ec2_image_info] ||= {}).merge!({
      %w[us-east-1  64-bit  ebs     ironfan-precise  ] =>
      { image_id: 'ami-29fe7640', ssh_user: 'bam', bootstrap_distro: 'ubuntu12.04-ironfan' },
    })

    Ironfan.realm(:foo) do
      environment   :bif

      cloud(:ec2) do
        flavor      'm1.xlarge'
        image_name  'ironfan-precise'
      end
      
      cluster(:bar) do
        cluster_role.override_attributes(a: 1)

        facet(:baz) do
          instances 1
          role      :blah
          facet_role.override_attributes(b: 1)
        end
      end
    end
  end

  after(:each) do
    Ironfan.clusters.clear
    Ironfan.realms.clear
  end

  def manifest    
    Ironfan.cluster(:bar).resolve.facets[:baz].server(0).to_machine_manifest
  end

  it 'chooses its own name as its default environment' do
    Ironfan.realm(:bar){ }.environment.to_s.should == 'bar'
  end

  it 'chooses the widest possible cookbook contraints to satisfy all plugins' do
    Ironfan::Dsl::Component.template(%w[jib jab]) do
      require_strict_versioning false

      cookbook_req 'bif', '>= 1.0.0'
      def project(_) end
    end

    Ironfan::Dsl::Component.template(%w[dig dug]) do
      require_strict_versioning false

      cookbook_req 'bif', '>= 2.0.0'
      def project(_) end
    end

    Ironfan.realm(:qux) do
      cluster(:cuz) do
        facet(:lix) do
          jib_jab
          dig_dug
        end
      end
    end.cookbook_reqs['bif'].should == '>= 2.0.0'
  end

  it 'complains when no cookbook constraints can satisfy all plugins' do
    Ironfan::Dsl::Component.template(%w[bam pow]) do
      require_strict_versioning false

      cookbook_req 'bif', '~> 1.0.0'
      def project(_) end
    end

    Ironfan::Dsl::Component.template(%w[jam wam]) do
      require_strict_versioning false

      cookbook_req 'bif', '>= 2.0.0'
      def project(_) end
    end

    Ironfan.realm(:qux) do
      cluster(:cuz) do
        facet(:lix) do
          bam_pow
          jam_wam
        end
      end
    end

    expect{ Ironfan.realm(:qux).cookbook_reqs }.to raise_error
  end

  it 'creates clusters that can be referenced later' do
    test_scope = self
    Ironfan.realm :xx do
      cluster(:bar).should test_scope.be(cluster(:bar))
    end
  end

  it 'should create clusters that can be edited later' do
    Ironfan.realm :xy do
      cluster(:baz)
    end

    Ironfan.cluster(:baz) do
      facet :bif
    end

    Ironfan.realm(:xy).cluster(:baz).facets.to_a.should_not(be_empty)
    Ironfan.realm(:xy).cluster(:baz).servers.to_a.first.should_not(be_nil)
  end

  it 'should create clusters with names prefixed by its own' do
    Ironfan.cluster(:bar).should_not(be_nil)
  end

  it 'should create clusters with machines' do
    Ironfan.cluster(:bar).facets[:baz].server(0).should_not(be_nil)
  end

  it 'should create clusters with attributes correctly applied' do    
    manifest.cluster_override_attributes.should == {a: 1}
    manifest.facet_override_attributes.should == {b: 1}
    manifest.run_list.should == %w[role[blah] role[foo-bar-cluster] role[foo-bar-baz-facet]]
  end

  it 'should create clusters with the correct ssh user' do
    manifest.flavor.should == 'm1.xlarge'
    manifest.ssh_user.should == 'bam'
  end

  it 'should save cloud properties to be shared among all clusters within the realm' do
    # We need to resolve before the cloud settings come through
    Ironfan.realm(:foo).clusters[:bar].resolve.facets[:baz].servers.to_a.first.to_machine_manifest.flavor.should == 'm1.xlarge'

    # Ironfan.cluster will do the resolution for us.
    manifest.flavor.should == 'm1.xlarge'
  end

  it 'should save an environment to be shared among all clusters within the realm' do
    # We need to resolve before the cloud settings come through
    Ironfan.realm(:foo).resolve.clusters[:bar].facets[:baz].environment.should == :bif

    # The server manifest should contain the environment.
    manifest.environment.should == :bif

    # Ironfan.cluster will do the resolution for us.
    Ironfan.cluster(:bar).resolve.facets[:baz].environment.should == :bif
  end
end
