require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require CLUSTER_CHEF_DIR("meta-cookbooks/provides_service/libraries/discovery.rb")
require 'chef/node'

describe ClusterChef::Discovery do

  describe ClusterChef::Discovery::StructAttr do
    let(:car_class){    Struct.new(:name, :model, :doors, :engine){   include ClusterChef::Discovery::StructAttr } }
    let(:engine_class){ Struct.new(:name, :displacement, :cylinders){ include ClusterChef::Discovery::StructAttr } }
    let(:chevy_350){    engine_class.new('chevy', 350, 8) }
    let(:hot_rod){      car_class.new('39 ford', 'tudor', 2, chevy_350) }

    context '#to_hash' do
      it('succeeds'){  chevy_350.to_hash.should == { 'name' => 'chevy', 'displacement' => 350, 'cylinders' => 8} }
      it('nests'){     hot_rod.to_hash.should   == { "name" => "39 ford", "model" => "tudor", "doors" => 2, "engine"=> { 'name' => 'chevy', 'displacement' => 350, 'cylinders' => 8} } }
      it('is a Hash'){ hot_rod.to_hash.class.should == Hash }
    end

    context '#to_mash' do
      it('succeeds') do
        msh = chevy_350.to_mash
        msh.should == Mash.new({ 'name' => 'chevy', 'displacement' => 350, 'cylinders' => 8})
        msh['name'].should == 'chevy'
        msh[:name ].should == 'chevy'
      end
      it('nests'){     hot_rod.to_mash.should   == Mash.new({ "name" => "39 ford", "model" => "tudor", "doors" => 2, "engine"=> { 'name' => 'chevy', 'displacement' => 350, 'cylinders' => 8} }) }
      it('is a Mash'){ hot_rod.to_mash.class.should == Mash }
    end

    let(:node_json){ nd_json = JSON.parse(File.read(CLUSTER_CHEF_DIR('spec/fixtures/chef_node-el_ridiculoso-aqui-0.json'))) }
    let(:chef_node) do
      nd = Chef::Node.new ; nd.consume_attributes(node_json)
      nd.name(node_json["name"]) ; nd.chef_environment(node_json["chef_environment"])
      nd
    end

    context 'stores into node' do
      it 'loads the node from its fixture' do
        node_json.keys.should == ["chef_type", "name", "chef_environment", "languages", "kernel", "os", "os_version", "virtualization", "hostname", "fqdn", "domain", "network", "counters", "ipaddress", "macaddress", "virtualbox", "chef_packages", "etc", "current_user", "dmi", "cloud", "keys", "ohai_time", "command", "lsb", "platform", "platform_version", "uptime_seconds", "uptime", "idletime_seconds", "idletime", "memory", "block_device", "filesystem", "cpu", "node_name", "cluster_name", "facet_name", "facet_index", "chef_server", "nfs", "pkg_sets", "server_tuning", "java", "apt", "mountable_volumes", "hadoop", "hbase", "zookeeper", "flume", "end", "tags", "value_for_platform", "runit", "provides_service", "cluster_chef", "apt_cacher", "ntp", "users", "firewall", "thrift", "python", "install_from", "groups", "cluster_size", "ganglia", "redis", "resque", "aws", "recipe", "role", "run_list"]
        chef_node.name.should == 'el_ridiculoso-aqui-0'
        chef_node[:cloud][:public_ipv4].should == "10.0.2.15"
      end

      it 'into variable as directed' do
        hot_rod.store_into_node(chef_node, 'car')
        p chef_node.to_hash
        chef_node[:car][:model].should == 'tudor'
        chef_node[:car].should be_a(Chef::Node::Attribute)
      end


    end
  end

end
