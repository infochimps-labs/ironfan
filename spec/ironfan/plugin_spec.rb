require_relative '../spec_helper.rb'

describe MyPlugin do
  subject { MyPlugin }

  it 'should respond to template' do
    subject.should(respond_to(:template))
  end

  context 'when templatizing plugins' do
    after(:each) do
      uncreate_plugin(subject, Foo)
    end
    before(:each) do
      subject.template(%w[baz bif])
    end

    it 'should create them as classes within itself' do
      subject.constants.should(include(:BazBif))
    end
    it 'should create them as subclasses of itself' do
      subject.const_get(:BazBif).should(be < subject)
    end
    it 'should allow customizing the classes' do
      uncreate_plugin(subject, Foo)
      subject.template(%w[baz bif]){ def bam() end }
      subject.const_get(:BazBif).new.should(respond_to(:bam))
    end
    it 'should register methods on the specified class' do
      Foo.new.should(respond_to(:baz_bif))
    end
    it 'should wire those methods to the plugin_hook method of itself' do
      foo = Foo.new
      subject.should_receive(:plugin_hook).with(foo, {}, :baz, :baz_bif)
      foo.baz_bif
    end
    it 'should allow the user to create a custom class that will also be registered' do
      Foo.registry[:baz_bif].should(be(subject.const_get(:BazBif)))
    end
  end
end

describe Ironfan::Dsl::Component do
  before(:each) do
    Ironfan::Dsl::Component.template(%w[baz bif]) do
      include Ironfan::Dsl::Component::Announcement

      magic :bam, Symbol, node_attr: 'a.b.c', default: nil

      def project(compute)
        compute.role(:called_from_project, compute) unless bam
      end
    end
  end

  after(:each) do
    uncreate_plugin(Ironfan::Dsl::Component, Ironfan::Dsl::Compute)
  end

  it 'should have its project method called by the plugin_hook' do
    rspec_nest = self
    Ironfan.cluster(:foo) do
      should(rspec_nest.receive(:role).with(:called_from_project, self))
      baz_bif
    end
  end

  it 'should merge its node attribute to create a node' do
    node = Chef::Node.new
    node.set['a'] = {'b' => {'c' => :baz}}
    Ironfan.cluster(:foo) do
      baz_bif{ bam(:baz) }.to_node.to_hash.should == node.to_hash
    end
  end
  it 'should be instantiable from a node object' do
    node = Chef::Node.new
    node.set['a'] = {'b' => {'c' => :baz}}
    Ironfan::Dsl::Compute.registry[:baz_bif].from_node(node).bam.should == :baz
  end

  it 'should remember all of its node attributes' do
    Ironfan.cluster(:foo) do
      component = baz_bif{ bam(:baz) }
      component.to_node.to_hash.should ==
        Ironfan::Dsl::Compute.registry[:baz_bif].from_node(component.to_node).to_node.to_hash
    end
  end

  context 'when announcing' do
    before (:each) do
      def make_plugin(name, server_b)
        Ironfan::Dsl::Component.template([name, server_b ? 'server' : 'client']) do
          include Ironfan::Dsl::Component::Announcement if server_b
          include Ironfan::Dsl::Component::Discovery    if not server_b

          if server_b
            def project(compute)
            end
          else
            def project(compute)
              set_discovery compute, [announce_name]
            end
          end
        end
      end

      def make_plugin_pair(name) make_plugin(name, true); make_plugin(name, false); end

      make_plugin_pair(:bam); make_plugin_pair(:pow)
    end

    it 'automatically discovers announcements within realms' do
      Ironfan.realm(:wap) do
        cluster(:foo){ bam_client; pow_server }
        cluster(:bar){ bam_server; pow_client }

        cluster(:foo).cluster_role.override_attributes[:discovers].should == {bam: :wap_bar}
        cluster(:bar).cluster_role.override_attributes[:discovers].should == {pow: :wap_foo}
      end
    end
  end
end
