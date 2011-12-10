shared_context 'dummy_chef' do
  before(:each) do
    Chef::Log.logger = Logger.new(StringIO.new)

    Chef::Config[:node_name]  = "webmonkey.example.com"
    ClusterChef.ui = Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
    ClusterChef.ui.stub!(:puts)
    ClusterChef.ui.stub!(:print)
    Chef::Log.stub!(:init)
    Chef::Log.stub!(:level)
    [:debug, :info, :warn, :error, :crit].each do |level_sym|
      Chef::Log.stub!(level_sym)
    end
    Chef::Knife.stub!(:puts)
    @stdout = StringIO.new
  end


  let(:node_name){  'a_dummy_node' }
  let(:dummy_node){ Chef::Node.new }
  before(:each) do
    # ClusterChef::Cluster.stub!(:chef_nodes).and_return( [dummy_node] )
    ClusterChef::Server.stub!(:chef_node).and_return( dummy_node )
  end
end
