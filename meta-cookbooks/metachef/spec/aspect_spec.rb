require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require METACHEF_DIR("libraries/metachef")
require METACHEF_DIR("libraries/aspects")

describe ClusterChef::Aspect do
  include_context 'dummy_chef'

  let(:foo_aspect){ Class.new(ClusterChef::Aspect){ def self.handle() :foo end } }
  after(:each) do
    ClusterChef::Component.keys.delete(:foos)
    ClusterChef::Component.aspect_types.delete(:foos)
  end

  it 'knows its handle' do
    foo_aspect.handle.should == :foo
  end

  context 'register!' do
    it 'shows up in the Component.aspect_types' do
      ClusterChef::Component.aspect_types.should_not include(foo_aspect)
      foo_aspect.register!
      ClusterChef::Component.aspect_types[:foos].should == foo_aspect
    end

    it 'means it is called when a Component#harvest_all aspects' do
      foo_aspect.register!
      rc = Chef::RunContext.new(Chef::Node.new, [])
      foo_aspect.should_receive(:harvest).with(rc, chef_server_component)
      chef_server_component.harvest_all(rc)
    end
  end

end
