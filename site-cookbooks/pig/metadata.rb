maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures pig"

depends          "java"
depends          "apt"
depends          "install_from"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "pig/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/lib/pig"

attribute "pig/install_url",
  :display_name          => "",
  :description           => "",
  :default               => "http://apache.mirrors.tds.net/pig/pig-0.9.1/pig-0.9.1.tar.gz"

attribute "pig/java_home",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/lib/jvm/java-6-sun/jre"

attribute "pig/zookeeper_jar_url",
  :display_name          => "",
  :description           => "",
  :default               => "https://repository.apache.org/content/repositories/releases/org/apache/zookeeper/zookeeper/3.3.1/zookeeper-3.3.1.jar"

attribute "pig/extra_jars",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar", "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar", "/usr/lib/zookeeper/zookeeper.jar"]

attribute "pig/extra_confs",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/etc/hbase/conf/hbase-default.xml", "/etc/hbase/conf/hbase-site.xml"]

attribute "pig/combine_splits",
  :display_name          => "",
  :description           => "",
  :default               => "false"
