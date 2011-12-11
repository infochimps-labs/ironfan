require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require METACHEF_DIR("libraries/metachef.rb")
require METACHEF_DIR("libraries/aspects")

describe ClusterChef::Component do
  include_context 'dummy_chef'

  context 'registering aspects' do
    let(:klass) do
      klass = Class.new(ClusterChef::Component)
      klass.has_aspect(ClusterChef::DaemonAspect)
      klass
    end
    let(:component){ klass.new(chef_node, :chef, :client) }

    it 'adds a set-or-return plural accessor' do
      component.daemons.should == {}
      component.daemons.should be_a(Mash)
      component.daemons( Mash.new({ 'hi' => :there}) )
      component.daemons.should == { 'hi' => :there }
      component.daemons.should be_a(Mash)
      lambda{ component.daemons(69) }.should raise_error(/be a kind of Mash/)
    end

    context 'makes a singular accessor' do
      let(:megatron){ ClusterChef::DaemonAspect.new(component, :megatron, 'megatron', 'gun', :start) }

      it 'that is set-or-return' do
        component.daemon(:megatron).should be_nil
        component.daemon(:megatron, megatron)
        component.daemon(:megatron).should == megatron
        component.daemons.should == { 'megatron' => megatron }
      end

      it 'that lets me manipulate the aspect in a block' do
        component.daemon(:megatron, megatron)
        component.daemon(:megatron).pattern.should == 'gun'
        expected_self = megatron
        component.daemon(:megatron) do
          self.pattern('robot')
          self.should == expected_self
        end
        component.daemon(:megatron).pattern.should == 'robot'
      end

      it 'that auto-vivifies the aspect for the block' do
        expected_component = component
        component.daemon(:grimlock) do
          self.name.should      == :grimlock
          self.component.should == expected_component
          self.pattern.should   == nil
          self.pattern             'dinosaur'
        end
        component.daemon(:grimlock).pattern.should == 'dinosaur'
        component.daemons.keys.should == ['grimlock']
      end
    end

    it 'sees all the registered aspects' do
      klass.aspect_types.should == Mash.new({ :daemons   => ClusterChef::DaemonAspect })
    end
  end

  context '.harvest_aspects' do
    before(:each) do
      component.harvest_all(chef_context)
    end

    context 'works on a complex example' do
      let(:component){ hadoop_datanode_component }

      it('daemon') do
        component.daemons.should == Mash.new({
            :hadoop_datanode => ClusterChef::DaemonAspect.new(component, "hadoop_datanode", "hadoop_datanode", "hadoop_datanode", 'start')
          })
      end
      it('port') do
        component.ports.should == Mash.new({
            :dash_port     => ClusterChef::PortAspect.new(component, "dash_port",      :dash,     "50075"),
            :ipc_port      => ClusterChef::PortAspect.new(component, "ipc_port",       :ipc,      "50020"),
            :jmx_dash_port => ClusterChef::PortAspect.new(component, "jmx_dash_port",  :jmx_dash, "8006"),
            :port          => ClusterChef::PortAspect.new(component, "port",           :port,     "50010"),
          })
      end
      it('dashboard') do
        component.dashboards.should == Mash.new({
            :dash     => ClusterChef::DashboardAspect.new(component, "dash",     :http_dash, "http://33.33.33.12:50075/"),
            :jmx_dash => ClusterChef::DashboardAspect.new(component, "jmx_dash", :jmx_dash,  "http://33.33.33.12:8006/"),
          })
      end
      it('log') do
        component.logs.should == Mash.new({
            :log => ClusterChef::LogAspect.new(component, "log",  :log,  ["/hadoop/log"])
          })
      end
      it('directory') do
        component.directories.should == Mash.new({
            :conf => ClusterChef::DirectoryAspect.new(component, "conf", :conf, ["/etc/hadoop/conf"]),
            :data => ClusterChef::DirectoryAspect.new(component, "data", :data, ["/mnt1/hadoop/hdfs/data", "/mnt2/hadoop/hdfs/data"]),
            :home => ClusterChef::DirectoryAspect.new(component, "home", :home, ["/usr/lib/hadoop"]),
            :log  => ClusterChef::DirectoryAspect.new(component, "log",  :log,  ["/hadoop/log"]),
            :pid  => ClusterChef::DirectoryAspect.new(component, "pid",  :pid,  ["/var/run/hadoop"]),
            :tmp  => ClusterChef::DirectoryAspect.new(component, "tmp",  :tmp,  ["/hadoop/tmp"]),
          })
      end
      it('exported') do
        component.exporteds.should == Mash.new({
            :confs => ClusterChef::ExportedAspect.new(component, "confs", :confs, ["/etc/hadoop/conf/core-site.xml", "/etc/hadoop/conf/hdfs-site.xml", "/etc/hadoop/conf/mapred-site.xml" ]),
            :jars  => ClusterChef::ExportedAspect.new(component, "jars",  :jars,  ["/usr/lib/hadoop/hadoop-core.jar","/usr/lib/hadoop/hadoop-examples.jar", "/usr/lib/hadoop/hadoop-test.jar", "/usr/lib/hadoop/hadoop-tools.jar" ]),
          })
      end
    end

  end

  context '#node_info' do
    it 'returns a mash' do
      chef_server_component.node_info.should be_a(Mash)
    end
    it 'extracts the node attribute tree' do
      chef_server_component.node_info.should == Mash.new({ :user => 'chef',    :port => 4000, :server => { :port => 4000 }, :webui  => { :port => 4040, :user => 'www-data' } })
    end
    it 'overrides system attrs with subsystem attrs' do
      chef_webui_component.node_info.should  == Mash.new({ :user => 'www-data', :port => 4040, :server => { :port => 4000 }, :webui  => { :port => 4040, :user => 'www-data' } })
    end
    it 'warns but does not fail if system is missing' do
      Chef::Log.should_receive(:warn).with("no system data in component 'mxyzptlk_shazbot', node 'node[el_ridiculoso-aqui-0]'")
      comp = ClusterChef::Component.new(dummy_node, :mxyzptlk, :shazbot)
      comp.node_info.should      == Mash.new
    end
    it 'warns but does not fail if subsystem is missing' do
      Chef::Log.should_receive(:warn).with("no subsystem data in component 'chef_zod', node 'node[el_ridiculoso-aqui-0]'")
      comp = ClusterChef::Component.new(dummy_node, :chef, :zod)
      comp.node_info.should    == Mash.new({ :user => 'chef',                    :server => { :port => 4000 }, :webui  => { :port => 4040, :user => 'www-data' } })
    end
  end

end
