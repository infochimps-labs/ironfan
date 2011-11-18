maintainer       "Jacob Perkins - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures jruby"

depends          "java"

recipe           "jruby::default",                     "Base configuration for jruby"
recipe           "jruby::gems",                        "Gems"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "jruby/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/lib/jruby"

attribute "jruby/install_url",
  :display_name          => "",
  :description           => "",
  :default               => "http://jruby.org.s3.amazonaws.com/downloads/1.5.6/jruby-bin-1.5.6.tar.gz"

attribute "jruby/extra_jars",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar", "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar", "/usr/lib/zookeeper/zookeeper.jar"]

attribute "jruby/combine_splits",
  :display_name          => "",
  :description           => "",
  :default               => "true"

attribute "java/java_home",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/lib/jvm/java-6-sun/jre"
