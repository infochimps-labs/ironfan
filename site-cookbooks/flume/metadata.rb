maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures flume"

depends          "java"
depends          "apt"
depends          "mountable_volumes"
depends          "provides_service"

recipe           "flume::default",                     "Base configuration for flume"
recipe           "flume::hbase_sink_plugin",           "Hbase Sink Plugin"
recipe           "flume::jruby_plugin",                "Jruby Plugin"
recipe           "flume::master",                      "Master"
recipe           "flume::node",                        "Node"
recipe           "flume::test_flow",                   "Test Flow"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "flume/cluster_name",
  :display_name          => "",
  :description           => "",
  :default               => "cluster_name"

attribute "flume/plugins",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "flume/classes",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "flume/classpath",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "flume/java_opts",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "flume/collector",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "flume/data_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/data/db/flume"

attribute "flume/master/external_zookeeper",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "flume/master/zookeeper_port",
  :display_name          => "",
  :description           => "",
  :default               => "2181"
