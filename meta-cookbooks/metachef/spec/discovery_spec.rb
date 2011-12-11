require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require METACHEF_DIR("libraries/metachef")
require METACHEF_DIR("libraries/aspects")

describe ClusterChef::Discovery do
  include_context 'dummy_chef'

  context '.announce' do

    context 'populates the node[:announces] tree' do
      before(:each) do
        ClusterChef::NodeUtils.stub!(:timestamp){ '20090102030405' }
      end
      subject{ recipe.node[:announces]['el_ridiculoso-chef-server'] }

      it 'with the component name' do
        recipe.announce(:chef, :server)
        recipe.node[:announces].should include('el_ridiculoso-chef-server')
      end
      it 'sets a timestamp' do
        ClusterChef::NodeUtils.should_receive(:timestamp).and_return('20010101223344')
        recipe.announce(:chef, :server)
        subject[:timestamp].should == '20010101223344'
      end
      it 'defaults the realm to the cluster name' do
        recipe.node[:cluster_name] = 'grimlock'
        recipe.announce(:chef, :server)
        comp = recipe.node[:announces]['grimlock-chef-server']
        comp[:realm].should == :grimlock
      end
      it 'lets me set the realm' do
        recipe.announce(:chef, :server, :realm => :bumblebee)
        comp = recipe.node[:announces]['bumblebee-chef-server']
        comp[:realm].should == :bumblebee
      end
      it 'stuffs the component in as a hash' do
        recipe.announce(:chef, :server)
        subject.to_hash.should == {
          'sys' => :chef, 'subsys' => :server,
          'name' => 'chef_server', 'realm'  => :el_ridiculoso, 'timestamp' => "20090102030405",
          'daemons' => {}, 'ports' => {}, 'dashboards' => {}, 'logs' => {}, 'directories' => {}, 'exporteds' => {},
        }
      end
      it 'lets the node know it changed' do
        recipe.should_receive(:node_changed!)
        recipe.announce(:chef, :server)
      end
    end

    it 'returns the announced component' do
      component = recipe.announce(:chef, :server)
      component.should be_a(ClusterChef::Component)
      component.fullname.should == 'el_ridiculoso-chef-server'
    end

    context 'lets me play around in the component' do
      it 'instance_evals a block' do
        comp = recipe.announce(:chef, :server) do
          log(:log){ dirs ['better/than/bad/its/good'] }
        end
        # comp.log(:log).dirs.should == ['better/than/bad/its/good']
        # recipe.node[:announces]['el_ridiculoso-chef-server'].should == {}
      end
    end
  end

  context '.discover_all_nodes' do
    before(:each) do
      dummy_recipe.stub!(:search).
        with(:node, 'announces:el_ridiculoso-hadoop-datanode').
        and_return( all_nodes.values_at('el_ridiculoso-aqui-0', 'el_ridiculoso-pequeno-0') )
      dummy_recipe.stub!(:search).
        with(:node, 'announces:el_ridiculoso-hadoop-tasktracker').
        and_return( all_nodes.values_at('el_ridiculoso-aqui-0', 'el_ridiculoso-pequeno-0') )
      dummy_recipe.stub!(:search).
        with(:node, 'announces:el_ridiculoso-redis-server').
        and_return( all_nodes.values_at('el_ridiculoso-aqui-0') )
      dummy_recipe.stub!(:search).
        with(:node, 'announces:cocina-chef-client').
        and_return( all_nodes.values )
    end
    it 'finds nodes matching the request, sorted by timestamp' do
      result = dummy_recipe.discover_all_nodes("el_ridiculoso-hadoop-datanode")
      result.map{|nd| nd.name }.should == ['el_ridiculoso-pequeno-0', 'el_ridiculoso-aqui-0']
    end

    it 'replaces itself with a current copy in the search results' do
      result = dummy_recipe.discover_all_nodes("el_ridiculoso-hadoop-datanode")
      result.map{|nd| nd.name }.should == ['el_ridiculoso-pequeno-0', 'el_ridiculoso-aqui-0']
      result[1].should have_key(:nfs)
    end
    it 'finds current node if it has announced (even when the server\'s copy has not)' do
      result = dummy_recipe.discover_all_nodes("el_ridiculoso-redis-server")
      result.map{|nd| nd.name }.should == ['el_ridiculoso-aqui-0']
      result[0].should have_key(:nfs)
    end
    it 'does not find current node if it has not announced (even when the server\'s copy has announced)' do
      result = dummy_recipe.discover_all_nodes("el_ridiculoso-hadoop-tasktracker")
      result.map{|nd| nd.name }.should == ['el_ridiculoso-pequeno-0']
    end
    it 'when no server found warns and returns an empty hash' do
      dummy_recipe.should_receive(:search).
        with(:node, 'announces:el_ridiculoso-hadoop-mxyzptlk').and_return([])
      Chef::Log.should_receive(:warn).with("No node announced for 'el_ridiculoso-hadoop-mxyzptlk'")
      result = dummy_recipe.discover_all_nodes("el_ridiculoso-hadoop-mxyzptlk")
      result.should == []
    end
  end

  it 'loads the node from its fixture' do
    node_json.keys.sort.should == ["apt", "apt_cacher", "aws", "block_device", "chef_environment", "chef_packages", "chef_server", "chef_type", "cloud", "metachef", "cluster_name", "cluster_size", "command", "cpu", "current_user", "discovery", "dmi", "domain", "end", "etc", "facet_index", "facet_name", "filesystem", "firewall", "flume", "fqdn", "ganglia", "groups", "hadoop", "hbase", "hostname", "install_from", "ipaddress", "java", "jruby", "kernel", "languages", "lsb", "macaddress", "memory", "mountable_volumes", "name", "network", "nfs", "node_name", "nodejs", "ntp", "os", "os_version", "pig", "pkg_sets", "platform", "platform_version", "python", "recipes", "redis", "resque", "rstats", "run_list", "runit", "server_tuning", "tags", "thrift", "users", "value_for_platform", "virtualbox", "virtualization", "zookeeper"]
    chef_node.name.should == 'el_ridiculoso-aqui-0'
    chef_node[:cloud][:public_ipv4].should == "10.0.2.15"
  end

end
