maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures pig"

depends          "hadoop_cluster"
depends          "install_from"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "pig/home_dir",
  :default               => "/usr/lib/pig",
  :display_name          => "",
  :description           => ""

attribute "pig/install_url",
  :default               => "http://apache.mirrors.tds.net/pig/pig-0.9.1/pig-0.9.1.tar.gz",
  :display_name          => "",
  :description           => ""

attribute "pig/java_home",
  :default               => "/usr/lib/jvm/java-6-sun/jre",
  :display_name          => "",
  :description           => ""

attribute "pig/zookeeper_jar_url",
  :default               => "https://repository.apache.org/content/repositories/releases/org/apache/zookeeper/zookeeper/3.3.1/zookeeper-3.3.1.jar",
  :display_name          => "",
  :description           => ""

attribute "pig/extra_jars",
  :type                  => "array",
  :default               => ["/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar", "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar", "/usr/lib/zookeeper/zookeeper.jar"],
  :display_name          => "",
  :description           => ""

attribute "pig/extra_confs",
  :type                  => "array",
  :default               => ["/etc/hbase/conf/hbase-default.xml", "/etc/hbase/conf/hbase-site.xml"],
  :display_name          => "",
  :description           => ""

attribute "pig/combine_splits",
  :default               => "false",
  :display_name          => "",
  :description           => ""
