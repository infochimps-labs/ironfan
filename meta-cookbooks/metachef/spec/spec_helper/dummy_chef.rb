require METACHEF_DIR("libraries/discovery")
CHEF_RESOURCE_CLXN = JSON.parse(File.read(METACHEF_DIR('spec/fixtures/chef_resources-el_ridiculoso-aqui-0.json')))

shared_context 'dummy_chef' do

  class DummyNode < Mash
    attr_accessor :cookbook_collection
    attr_accessor :name

    def initialize(name, *args, &block)
      self.name = name
      super(*args, &block)
    end

    def to_s
      "node[#{name}]"
    end
    def inspect
      to_s
    end
  end

  class DummyRecipe
    include ClusterChef::Discovery ; public :discover_all_nodes
    include ClusterChef::NodeUtils
    #
    attr_accessor :name, :node, :run_context
    def initialize(name, run_context)
      self.name        = name
      self.node        = run_context.node
      self.run_context = run_context
    end
  end

  let(:dummy_node) do
    DummyNode.new('el_ridiculoso-aqui-0', {
        :cluster_name => 'el_ridiculoso',
        :nfs  => {
          :server => { :user => 'nfsd', :port => 111 },
        },
        :chef => { :user => 'chef',
          :server => { :port => 4000 },
          :webui  => { :port => 4040, :user => 'www-data' },
        },
        :announces => {
          'cocina-chef-client'               => { :timestamp => '20110907' },
          'el_ridiculoso-hadoop-namenode'    => { :timestamp => '20110907' },
          'el_ridiculoso-hadoop-datanode'    => { :timestamp => '20110907' },
          'el_ridiculoso-redis-server'       => { :timestamp => '20110907' },
        }
      })
  end

  let(:all_nodes) do
    Mash.new({
        'el_ridiculoso-cocina-0' => DummyNode.new('el_ridiculoso-cocina-0', :announces => {
            'cocina:chef.server'               => { :timestamp => '20110902' },
            'cocina:chef.client'               => { :timestamp => '20110902' },
            'cocina:rabbitmq.server'           => { :timestamp => '20110902' },
            'cocina:couchdb.server'            => { :timestamp => '20110902' },
          } ),
        'el_ridiculoso-pequeno-0' => DummyNode.new('el_ridiculoso-pequeno-0', :announces => {
            'cocina:chef.client'               => { :timestamp => '20110903' },
            'el_ridiculoso-hadoop-datanode'    => { :timestamp => '20110903' },
            'el_ridiculoso-hadoop-tasktracker' => { :timestamp => '20110903' },
          } ),
        # note that this *does* announce tasktracker and *does not* announce redis-server
        # and lacks all the attributes on the actual node
        'el_ridiculoso-aqui-0'    => DummyNode.new('el_ridiculoso-aqui-0', :announces => {
            'cocina:chef.client'               => { :timestamp => '20110903' },
            'el_ridiculoso-hadoop-namenode'    => { :timestamp => '20110905' },
            'el_ridiculoso-hadoop-datanode'    => { :timestamp => '20110905' },
            'el_ridiculoso-hadoop-tasktracker' => { :timestamp => '20110905' },
          } ),
      })
  end

  let(:node_json){ JSON.parse(File.read(METACHEF_DIR('spec/fixtures/chef_node-el_ridiculoso-aqui-0.json'))) }
  let(:chef_node) do
    recipes = node_json.delete('recipes')
    nd = Chef::Node.new ; nd.consume_attributes(node_json)
    nd.name(node_json["name"]) ; nd.chef_environment(node_json["chef_environment"])
    nd.recipes = recipes
    nd
  end

  let(:chef_context) do
    rc = Chef::RunContext.new(chef_node, [])
    rc.resource_collection = CHEF_RESOURCE_CLXN
    rc
  end

  let(:dummy_context) do
    rc = Chef::RunContext.new(dummy_node, [])
    rc.resource_collection = CHEF_RESOURCE_CLXN
    rc
  end

  let(:recipe){       DummyRecipe.new(:hadoop, chef_context) }
  let(:dummy_recipe){ DummyRecipe.new(:hadoop, dummy_context) }

  let(:chef_server_component){ ClusterChef::Component.new(dummy_node, :chef, :server) }
  let(:chef_webui_component ){ ClusterChef::Component.new(dummy_node, :chef, :webui)  }

  let(:hadoop_namenode_component  ){ ClusterChef::Component.new(chef_node, :hadoop,    :namenode)  }
  let(:hadoop_datanode_component  ){ ClusterChef::Component.new(chef_node, :hadoop,    :datanode)  }
  let(:zookeeper_server_component ){ ClusterChef::Component.new(chef_node, :zookeeper, :server)  }
  let(:flume_node_component       ){ ClusterChef::Component.new(chef_node, :flume,     :node)  }
  let(:hbase_master_component     ){ ClusterChef::Component.new(chef_node, :hbase,     :master)  }
end
