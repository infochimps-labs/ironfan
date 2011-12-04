require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'chef/node'
require 'chef/resource_collection'
require CLUSTER_CHEF_DIR("meta-cookbooks/provides_service/libraries/discovery.rb")

# $: << '/Users/flip/ics/repos/awesome_print/lib'
require 'ap' # FIXME: remove

CHEF_RESOURCE_CLXN = JSON.parse(File.read(CLUSTER_CHEF_DIR('spec/fixtures/chef_resources-el_ridiculoso-aqui-0.json')))

describe ClusterChef do

  let(:node_json){ JSON.parse(File.read(CLUSTER_CHEF_DIR('spec/fixtures/chef_node-el_ridiculoso-aqui-0.json'))) }
  let(:chef_node) do
    recipes = node_json.delete('recipes')
    nd = Chef::Node.new ; nd.consume_attributes(node_json)
    nd.name(node_json["name"]) ; nd.chef_environment(node_json["chef_environment"])
    nd.recipes = recipes
    nd
  end

  let(:run_context) do
    rc = Chef::RunContext.new(chef_node, [])
    rc.resource_collection = CHEF_RESOURCE_CLXN
    rc
  end

  describe ClusterChef::Discovery do


    context '.announce' do
      context 'works on a complex example' do
        subject{ ClusterChef::Discovery.announce(run_context, :hadoop, :datanode) }

        #
        # FIXME: need to be able to pull info about hadoop *and* datanode
        #
        # these tests are thus accurately failing
        #

        it('daemon') do
          subject[:daemon].should == [
            ClusterChef::DaemonAspect.new("hadoop_datanode",  'datanode',  'stop') ]
        end
        it('port') do
          subject[:daemon].should == [
            ClusterChef::PortAspect.new("hadoop_datanode",  'datanode',  'stop') ]
        end
        it('dashboard') do
          subject[:dashboard].should == [
            ClusterChef::DashboardAspect.new("dash",     :http_dash, "http://33.33.33.12:50075/"),
            ClusterChef::DashboardAspect.new("jmx_dash", :jmx_dash,  "http://33.33.33.12:8006/"),
          ]
        end
        it('log') do
          subject[:log].should == [
            ClusterChef::LogAspect.new("log",  :log,  "/hadoop/log")
          ]
        end
        it('directory') do
          subject[:directory].should == [
            ClusterChef::DirectoryAspect.new("conf", :conf, "/etc/hadoop/conf"),
            ClusterChef::DirectoryAspect.new("data", :data, ["/mnt1/hadoop/hdfs/data", "/mnt2/hadoop/hdfs/data"] ),
            ClusterChef::DirectoryAspect.new("home", :home, "/usr/lib/hadoop"),
            ClusterChef::DirectoryAspect.new("log",  :log,  "/hadoop/log"),
            ClusterChef::DirectoryAspect.new("pid",  :pid,  "/var/run/hadoop"),
            ClusterChef::DirectoryAspect.new("tmp",  :tmp,  "/hadoop/tmp"),
          ]
        end
        it('exported') do
          subject[:exported].should == [
            ClusterChef::ExportedAspect.new("confs", :confs, ["/etc/hadoop/conf/core-site.xml", "/etc/hadoop/conf/hdfs-site.xml", "/etc/hadoop/conf/mapred-site.xml" ]),
            ClusterChef::ExportedAspect.new("jars",  :jars,  ["/usr/lib/hadoop/hadoop-core.jar","/usr/lib/hadoop/hadoop-examples.jar", "/usr/lib/hadoop/hadoop-test.jar", "/usr/lib/hadoop/hadoop-tools.jar" ]),
          ]
        end
      end
    end
  end

  describe ClusterChef::Aspect do
    let(:foo_aspect){ Struct.new('FooAspect', :name, :description){ include ClusterChef::Aspect } }
    after(:each) do
      Struct.send(:remove_const, :FooAspect) if defined?(Struct::FooAspect)
      ClusterChef::Aspect.registered.delete(:foo)
      ClusterChef::Aspect.registered.should_not include(:foo)
    end

    it 'can register itself' do
      ClusterChef::Aspect.registered.should_not include(foo_aspect)
      foo_aspect.register!
      ClusterChef::Aspect.registered.should include(:foo)
      ClusterChef::Aspect.registered.values.should include(foo_aspect)
    end

    it 'enumerates all registered aspects' do
      ClusterChef::Aspect.registered.should == Mash.new({
        :port => ClusterChef::PortAspect, :dashboard => ClusterChef::DashboardAspect, :daemon => ClusterChef::DaemonAspect,
        :log => ClusterChef::LogAspect, :directory => ClusterChef::DirectoryAspect,
        :exported => ClusterChef::ExportedAspect, :volume => ClusterChef::VolumeAspect
      })
    end

    it 'knows its handle' do
      foo_aspect.klass_handle.should == :foo
    end

    context '.harvest_all' do
      it 'passes the node to each aspect in turn' do
        foo_aspect.register!
        bob = Chef::RunContext.new(Chef::Node.new, [])
        foo_aspect.should_receive(:harvest).with(:billy, {}, bob)
        ClusterChef::Aspect.harvest_all(:billy, {}, bob)
      end
    end
  end

  describe :PortAspect do
    it 'is harvested by Aspects.harvest_all' do
      aspects = ClusterChef::Aspect.harvest_all(:hadoop, chef_node[:hadoop][:namenode], run_context)
      aspects[:port].should_not be_empty
      aspects[:port].each{|asp| asp.should be_a(ClusterChef::PortAspect) }
    end
    it 'harvests any "*_port" attributes' do
      port_aspects = ClusterChef::PortAspect.harvest(:hadoop, chef_node[:hadoop][:datanode], run_context)
      port_aspects.should == [
        ClusterChef::PortAspect.new("dash_port",      :dash_port,     "50075"),
        ClusterChef::PortAspect.new("ipc_port",       :ipc_port,      "50020"),
        ClusterChef::PortAspect.new("jmx_dash_port", :jmx_dash_port,  "8006"),
        ClusterChef::PortAspect.new("port",           :port,          "50010"),
      ]
    end
    # context '#addrs' do
    #   it 'can be marked :critical, :open, :closed or :ignore'
    #   it 'marks first private interface open by default'
    #   it 'marks other interfaces closed by default'
    # end
    # context '#flavor' do
    #   it 'accepts a defined flavor'
    # end
    # context '#monitors' do
    #   it 'accepts an arbitrary hash'
    # end
  end

  describe :DashboardAspect do
    it 'is harvested by Aspects.harvest_all' do
      aspects = ClusterChef::Aspect.harvest_all(:hadoop, chef_node[:hadoop][:namenode], run_context)
      aspects[:dashboard].should_not be_empty
      aspects[:dashboard].each{|asp| asp.should be_a(ClusterChef::DashboardAspect) }
    end
    it 'harvests any "dash_port" attributes' do
      dashboard_aspects = ClusterChef::DashboardAspect.harvest(:hadoop, chef_node[:hadoop][:namenode], run_context)
      dashboard_aspects.should == [
        ClusterChef::DashboardAspect.new("dash",     :http_dash, "http://33.33.33.12:50070/"),
        ClusterChef::DashboardAspect.new("jmx_dash", :jmx_dash,  "http://33.33.33.12:8004/"),
      ]
    end
    it 'by default harvests the url from the private_ip and dash_port'
    it 'lets me set the URL with an explicit template'
  end

  describe :DaemonAspect do
    # it 'is harvested by Aspects.harvest_all' do
    #   aspects = ClusterChef::Aspect.harvest_all(:hadoop, chef_node[:hadoop][:namenode], run_context)
    #   aspects[:daemon].should_not be_empty
    #   aspects[:daemon].each{|asp| asp.should be_a(ClusterChef::DaemonAspect) }
    # end
    it 'harvests its associated service resource' do
      info = Mash.new(chef_node[:zookeeper].to_hash).merge(chef_node[:zookeeper][:server])
      daemon_aspects = ClusterChef::DaemonAspect.harvest(:zookeeper, info, run_context)
      daemon_aspects.should == [
        ClusterChef::DaemonAspect.new("zookeeper", "zookeeper", 'stop'),
      ]
    end

    it 'harvesting many' do
      # rl = chef_node.run_list.map{|s| s.to_s.gsub(/(?:\Arecipe|role)\[([^:]+?)(?:::(.+))?\]\z/, '\1') }.compact.uniq.map(&:to_sym)
      run_context.node.recipes.map{|x| x.gsub(/::.*/, '') }.uniq.each do |sys_name|
        info = Mash.new(chef_node[sys_name])
        daemon_aspects = ClusterChef::DaemonAspect.harvest(sys_name, info, run_context)
      end
    end
    # context '#run_state' do
    #   it 'harvests the :run_state attribute'
    #   it 'can be set explicitly'
    #   it 'only accepts :start, :stop or :nothing'
    # end
    # context '#boot_state' do
    #   it 'harvests the :boot_state attribute'
    #   it 'can be set explicitly'
    #   it 'only accepts :enable, :disable or nil'
    # end
    # context '#pattern' do
    #   it 'harvests the :pattern attribute from the associated service resource'
    #   it 'is not settable explicitly'
    # end
    # context '#limits' do
    #   it 'accepts an arbitrary hash'
    #   it 'harvests the :limits hash'
    # end
  end

  describe :LogAspect do
    it 'is harvested by Aspects.harvest_all' do
      aspects = ClusterChef::Aspect.harvest_all(:flume, chef_node[:flume], run_context)
      aspects[:log].should_not be_empty
      aspects[:log].each{|asp| asp.should be_a(ClusterChef::LogAspect) }
    end
    it 'harvests any "log_dir" attributes' do
      log_aspects = ClusterChef::LogAspect.harvest(:flume, chef_node[:flume], run_context)
      log_aspects.should == [
        ClusterChef::LogAspect.new("log", :log, "/var/log/flume"),
      ]
    end
    # context '#flavor' do
    #   it 'accepts :http, :log4j, or :rails'
    # end
  end

  describe :DirectoryAspect do
    it 'is harvested by Aspects.harvest_all' do
      aspects = ClusterChef::Aspect.harvest_all(:zookeeper, chef_node[:zookeeper], run_context)
      aspects[:directory].should_not be_empty
      aspects[:directory].each{|asp| asp.should be_a(ClusterChef::DirectoryAspect) }
    end
    it 'harvests attributes ending with "_dir"' do
      directory_aspects = ClusterChef::DirectoryAspect.harvest(:flume, chef_node[:flume], run_context)
      directory_aspects.should == [
        ClusterChef::DirectoryAspect.new("conf", :conf, "/etc/flume/conf"),
        ClusterChef::DirectoryAspect.new("data", :data, "/data/db/flume"),
        ClusterChef::DirectoryAspect.new("home", :home, "/usr/lib/flume"),
        ClusterChef::DirectoryAspect.new("log",  :log,  "/var/log/flume"),
        ClusterChef::DirectoryAspect.new("pid",  :pid,  "/var/run/flume"),
      ]
    end
    it 'harvests plural directory sets ending with "_dirs"' do
      hadoop_namenode = Mash.new(chef_node[:hadoop].to_hash).merge(chef_node[:hadoop][:namenode])
      ap hadoop_namenode
      directory_aspects = ClusterChef::DirectoryAspect.harvest(:hadoop, hadoop_namenode, run_context)
      directory_aspects.should == [
        ClusterChef::DirectoryAspect.new("conf", :conf, "/etc/hadoop/conf"),
        ClusterChef::DirectoryAspect.new("data", :data, ["/mnt1/hadoop/hdfs/name", "/mnt2/hadoop/hdfs/name"]),
        ClusterChef::DirectoryAspect.new("home", :home, "/usr/lib/hadoop"),
        ClusterChef::DirectoryAspect.new("log",  :log,  "/hadoop/log"),
        ClusterChef::DirectoryAspect.new("pid",  :pid,  "/var/run/hadoop"),
        ClusterChef::DirectoryAspect.new("tmp",  :tmp,  "/hadoop/tmp"),
      ]
    end
    it 'harvests non-standard dirs' do
      chef_node[:flume][:foo_dirs] = ['/var/foo/flume', '/var/bar/flume']
      directory_aspects = ClusterChef::DirectoryAspect.harvest(:flume, chef_node[:flume], run_context)
      directory_aspects.should == [
        ClusterChef::DirectoryAspect.new("conf", :conf, "/etc/flume/conf"),
        ClusterChef::DirectoryAspect.new("data", :data, "/data/db/flume"),
        ClusterChef::DirectoryAspect.new("foo",  :foo, ["/var/foo/flume", "/var/bar/flume"]),
        ClusterChef::DirectoryAspect.new("home", :home, "/usr/lib/flume"),
        ClusterChef::DirectoryAspect.new("log",  :log,  "/var/log/flume"),
        ClusterChef::DirectoryAspect.new("pid",  :pid,  "/var/run/flume"),
      ]
    end
    it 'finds its associated resource' do
    end
    context 'permissions' do
      it 'finds its mode / owner / group from the associated respo'
    end

    # context '#flavor' do
    #   def good_flavors() [:home, :conf, :log, :tmp, :pid, :data, :lib, :journal, :cache] ; end
    #   it "accepts #{good_flavors}"
    # end
    # context '#limits' do
    #   it 'accepts an arbitrary hash'
    # end
  end

  describe :ExportedAspect do
    context '#files' do
      it 'is harvested by Aspects.harvest_all' do
        aspects = ClusterChef::Aspect.harvest_all(:zookeeper, chef_node[:zookeeper], run_context)
        aspects[:exported].should_not be_empty
        aspects[:exported].each{|asp| asp.should be_a(ClusterChef::ExportedAspect) }
      end
      it 'harvests attributes beginning with "exported_"' do
        exported_aspects = ClusterChef::ExportedAspect.harvest(:zookeeper, chef_node[:zookeeper], run_context)
        exported_aspects.should == [
          ClusterChef::ExportedAspect.new("jars", :jars, ["/usr/lib/zookeeper/zookeeper.jar"])
        ]
      end
      it 'harvests multiple examples' do
        exported_aspects = ClusterChef::ExportedAspect.harvest(:zookeeper, chef_node[:hbase], run_context)
        exported_aspects.should == [
          ClusterChef::ExportedAspect.new("confs", :confs, ["/etc/hbase/conf/hbase-default.xml", "/etc/hbase/conf/hbase-site.xml"]),
          ClusterChef::ExportedAspect.new("jars",  :jars,  ["/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar", "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar"])
        ]
      end
    end
  end

  # describe :CookbookAspect do
  # end
  #
  # describe :CronAspect do
  # end


  # __________________________________________________________________________
  #
  # Utils
  #

  describe ClusterChef::StructAttr do
    let(:car_class){    Struct.new(:name, :model, :doors, :engine){   include ClusterChef::StructAttr } }
    let(:engine_class){ Struct.new(:name, :displacement, :cylinders){ include ClusterChef::StructAttr } }
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

    context 'stores into node' do
      it 'loads the node from its fixture' do
        node_json.keys.should == ["chef_type", "name", "chef_environment", "languages", "kernel", "os", "os_version", "virtualization", "hostname", "fqdn", "domain", "network", "ipaddress", "macaddress", "virtualbox", "chef_packages", "etc", "current_user", "dmi", "cloud", "command", "lsb", "platform", "platform_version", "memory", "block_device", "filesystem", "cpu", "node_name", "cluster_name", "facet_name", "facet_index", "chef_server", "nfs", "recipes", "pkg_sets", "server_tuning", "java", "apt", "mountable_volumes", "hadoop", "hbase", "zookeeper", "flume", "end", "tags", "value_for_platform", "runit", "provides_service", "cluster_chef", "apt_cacher", "ntp", "users", "firewall", "thrift", "python", "install_from", "groups", "cluster_size", "ganglia", "redis", "resque", "pig", "rstats", "nodejs", "jruby", "aws", "run_list"]
        chef_node.name.should == 'el_ridiculoso-aqui-0'
        chef_node[:cloud][:public_ipv4].should == "10.0.2.15"
      end

      it 'into variable as directed' do
        hot_rod.store_into_node(chef_node, 'car')
        chef_node[:car][:model].should == 'tudor'
        chef_node[:car].should be_a(Chef::Node::Attribute)
      end
    end
  end

  describe :AttrTemplateString do
    # * (:any attr:) (:node_name:) (:private_ip:) public_ip cluster facet facet_idx
  end

end
