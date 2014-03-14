require 'spec_helper.rb'

describe Ironfan::Plugin::Base do
  
  let(:target_class){ Class.new }
  let(:plugin_class) do   
    plugin_base = described_class
    other_class = target_class
    Class.new do
      include plugin_base
      register_with other_class

      def self.plugin_hook(*_) end
    end
  end

  subject(:example_plugin){ plugin_class }
  
  context '.template' do
    before(:each){ example_plugin.template %w[baz bif] }

    it 'defines templates as classes within itself' do
      example_plugin.const_defined?(:BazBif).should be_true
    end
    
    it 'defines templates as subclasses of itself' do
      example_plugin.const_get(:BazBif).should be < subject
    end
    
    it 'allows for customizing class definitions' do
      example_plugin.template(%w[gig bag]){ def bam() ; end }
      example_plugin.const_get(:GigBag).new.should respond_to(:bam)
    end

    it 'registers methods on the template class' do
      target_class.new.should respond_to(:baz_bif)
    end

    it 'wires those methods to the plugin_hook method of itself' do
      target = target_class.new
      example_plugin.should_receive(:plugin_hook).with(target, {}, :baz, :baz_bif)
      target.baz_bif
    end

    it 'registers the newly created class' do
      target_class.registry[:baz_bif].should be(example_plugin.const_get(:BazBif))
    end
  end
end

describe Ironfan::Dsl::Component do

  def uncreate_plugin(plugin_class, target_class)
    target_class.registry.clear
    plugin_class.instance_eval{ remove_const :BazBif }
  end

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
    Ironfan.cluster(:foo) do
      should_receive(:role).with(:called_from_project, self)
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
      def make_plugin(name, server_b, bidirectional)
        Ironfan::Dsl::Component.template([name, server_b ? 'server' : 'client']) do
          include Ironfan::Dsl::Component::Announcement if server_b
          include Ironfan::Dsl::Component::Discovery    if not server_b

          if bidirectional and not server_b
            default_to_bidirectional
          end

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

      def make_plugin_pair(name, bidirectional = false)
        make_plugin(name, true,  bidirectional);
        make_plugin(name, false, bidirectional);
      end

      make_plugin_pair(:bam)
      make_plugin_pair(:pow)
      make_plugin_pair(:zap, true)
      make_plugin_pair(:bop)

      Ironfan.realm(:wap) do
        cloud(:ec2)

        cluster(:foo) do
          bam_client{ server_cluster :bar }
          pow_server
        end

        cluster(:bar) do
          bam_server
          pow_client{ server_cluster :foo }
        end

        cluster(:baz) do
          zap_client{ server_cluster :bif }
        end

        cluster(:bif) do
          zap_server
        end

        cluster(:bam) do
          facet(:wak) do
            bop_client{ server_cluster :bop }
          end
        end

        cluster(:bop) do
          facet(:pow) do
            bop_server
          end
        end

      end.resolve!
    end

    after(:each) do
      [
       :BamServer, :BamClient, :PowServer, :PowClient,
       :ZapClient, :ZapServer, :BopServer, :BopClient,
       ].each do |class_name|
        Ironfan::Dsl::Component.send(:remove_const, class_name)
      end
    end

    it 'configures the correct security groups during discovery' do
      foo_group = Ironfan.realm(:wap).cluster(:foo).security_group('foo')
      bar_group = Ironfan.realm(:wap).cluster(:bar).security_group('bar')

      foo_group.group_authorized_by.should include('bar')
      bar_group.group_authorized_by.should include('foo')
    end

    it 'configures the correct security groups during bidirectional discovery' do
      baz_group = Ironfan.realm(:wap).cluster(:baz).security_group('baz')
      bif_group = Ironfan.realm(:wap).cluster(:bif).security_group('bif')

      baz_group.group_authorized_by.should include('bif')
      baz_group.group_authorized.should    include('bif')
    end

    it 'does not configure extra security groups during bidirectional discovery' do
      Ironfan.realm(:wap).cluster(:baz).security_groups.keys.should_not include('wap_bif')
    end

    it 'correctly sets the server cluster even when the client and server facets differ' do
      bam_wak_group = Ironfan.realm(:wap).cluster(:bam).facet(:wak).security_group('bam-wak')
      bam_wak_group.group_authorized_by.should include('bop')
    end

  end
end
