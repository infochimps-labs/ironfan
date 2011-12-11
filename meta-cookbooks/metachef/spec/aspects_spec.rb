require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require METACHEF_DIR("libraries/metachef")
require METACHEF_DIR("libraries/aspects")

describe 'aspect' do
  include_context 'dummy_chef'

  def harvest_klass(component)
    described_class.harvest(chef_context, component)
  end
  let(:component){ hadoop_datanode_component }
  let(:harvested){ harvest_klass(component) }
  let(:subject){   harvested.values.first   }

  describe ClusterChef::PortAspect do
    it 'harvests any "*_port" attributes' do
      harvested.should == Mash.new({
          :dash_port     => ClusterChef::PortAspect.new(component, "dash_port",      :dash,     "50075"),
          :ipc_port      => ClusterChef::PortAspect.new(component, "ipc_port",       :ipc,      "50020"),
          :jmx_dash_port => ClusterChef::PortAspect.new(component, "jmx_dash_port", :jmx_dash,  "8006"),
          :port          => ClusterChef::PortAspect.new(component, "port",           :port,     "50010"),
        })
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

  describe ClusterChef::DashboardAspect do
    it 'harvests any "dash_port" attributes' do
      harvested.should == Mash.new({
          :dash     => ClusterChef::DashboardAspect.new(component, "dash",     :http_dash, "http://33.33.33.12:50075/"),
          :jmx_dash => ClusterChef::DashboardAspect.new(component, "jmx_dash", :jmx_dash,  "http://33.33.33.12:8006/"),
        })
    end
    it 'by default harvests the url from the private_ip and dash_port'
    it 'lets me set the URL with an explicit template'
  end

  describe ClusterChef::DaemonAspect do
    it 'harvests its associated service resource' do
      harvested.should == Mash.new({
          :hadoop_datanode => ClusterChef::DaemonAspect.new(component, "hadoop_datanode", "hadoop_datanode", "hadoop_datanode", 'start'),
        })
    end

    context '#run_state' do
      it 'harvests the :run_state attribute' do
        subject.run_state.should == 'start'
      end
      it 'only accepts :start, :stop or :nothing' do
        chef_node[:hadoop][:datanode][:run_state] = 'shazbot'
        Chef::Log.should_receive(:warn).with("Odd run_state shazbot for daemon hadoop_datanode: set node[:hadoop][:datanode] to :stop, :start or :nothing")
        subject.lint
      end
    end

    # context '#service_name' do
    #   it 'defaults to' do
    #
    #   end
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

  describe ClusterChef::LogAspect do
    let(:component){ flume_node_component }
    it 'harvests any "log_dir" attributes' do
      harvested.should == Mash.new({
          :log => ClusterChef::LogAspect.new(component, "log", :log, ["/var/log/flume"]),
        })
    end
    # context '#flavor' do
    #   it 'accepts :http, :log4j, or :rails'
    # end
  end

  describe ClusterChef::DirectoryAspect do
    let(:component){ flume_node_component }
    it 'harvests attributes ending with "_dir"' do
      harvested.should == Mash.new({
          :conf => ClusterChef::DirectoryAspect.new(component, "conf", :conf, ["/etc/flume/conf"]),
          :data => ClusterChef::DirectoryAspect.new(component, "data", :data, ["/data/db/flume"]),
          :home => ClusterChef::DirectoryAspect.new(component, "home", :home, ["/usr/lib/flume"]),
          :log  => ClusterChef::DirectoryAspect.new(component, "log",  :log,  ["/var/log/flume"]),
          :pid  => ClusterChef::DirectoryAspect.new(component, "pid",  :pid,  ["/var/run/flume"]),
        })
    end
    it 'harvests non-standard dirs' do
      chef_node[:flume][:foo_dirs] = ['/var/foo/flume', '/var/bar/flume']
      directory_aspects = harvest_klass(flume_node_component)
      directory_aspects.should == Mash.new({
          :conf => ClusterChef::DirectoryAspect.new(component, "conf", :conf, ["/etc/flume/conf"]),
          :data => ClusterChef::DirectoryAspect.new(component, "data", :data, ["/data/db/flume"]),
          :foo  => ClusterChef::DirectoryAspect.new(component, "foo",  :foo,  ["/var/foo/flume", "/var/bar/flume"]),
          :home => ClusterChef::DirectoryAspect.new(component, "home", :home, ["/usr/lib/flume"]),
          :log  => ClusterChef::DirectoryAspect.new(component, "log",  :log,  ["/var/log/flume"]),
          :pid  => ClusterChef::DirectoryAspect.new(component, "pid",  :pid,  ["/var/run/flume"]),
        })
    end
    it 'harvests plural directory sets ending with "_dirs"' do
      component = hadoop_namenode_component
      directory_aspects = harvest_klass(component)
      directory_aspects.should == Mash.new({
          :conf => ClusterChef::DirectoryAspect.new(component, "conf", :conf, ["/etc/hadoop/conf"]),
          :data => ClusterChef::DirectoryAspect.new(component, "data", :data, ["/mnt1/hadoop/hdfs/name", "/mnt2/hadoop/hdfs/name"]),
          :home => ClusterChef::DirectoryAspect.new(component, "home", :home, ["/usr/lib/hadoop"]),
          :log  => ClusterChef::DirectoryAspect.new(component, "log",  :log,  ["/hadoop/log"]),
          :pid  => ClusterChef::DirectoryAspect.new(component, "pid",  :pid,  ["/var/run/hadoop"]),
          :tmp  => ClusterChef::DirectoryAspect.new(component, "tmp",  :tmp,  ["/hadoop/tmp"]),
        })
    end

    # it 'finds its associated resource'
    # context 'permissions' do
    #   it 'finds its mode / owner / group from the associated respo'
    # end
    #
    # context '#flavor' do
    #   def good_flavors() [:home, :conf, :log, :tmp, :pid, :data, :lib, :journal, :cache] ; end
    #   it "accepts #{good_flavors}"
    # end
    # context '#limits' do
    #   it 'accepts an arbitrary hash'
    # end
  end

  describe ClusterChef::ExportedAspect do
    # context '#files' do
    #   let(:component){ hbase_master_component }
    #   it 'harvests attributes beginning with "exported_"' do
    #     harvested.should == Mash.new({
    #         :confs => ClusterChef::ExportedAspect.new(component, "confs", :confs, ["/etc/hbase/conf/hbase-default.xml", "/etc/hbase/conf/hbase-site.xml"]),
    #         :jars  => ClusterChef::ExportedAspect.new(component, "jars",  :jars,  ["/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar", "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar"])
    #       })
    #   end
    # end

    it 'converts flavor to sym' do
      subject.flavor('hi').should == :hi
      subject.flavor.should       == :hi
    end
  end

  # describe ClusterChef::CookbookAspect do
  # end
  #
  # describe ClusterChef::CronAspect do
  # end

end
