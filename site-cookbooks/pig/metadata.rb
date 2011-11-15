maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs pig, a data analysis program for hadoop. It's like SQL but awesome and infinitely scalable."

depends          "java"
depends          "apt"
depends          "install_from"

recipe           "pig::default",                       "Base configuration for pig"
recipe           "pig::install_from_package",          "Installs pig from the cloudera package -- verified compatible, but on a slow update schedule."
recipe           "pig::install_from_release",          "Install From the release tarball."
recipe           "pig::integration",                   "Link in jars from hbase and zookeeper"
recipe           "pig::piggybank",                     "Compiles the Piggybank, a library of useful functions for pig"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "pig/home_dir",
  :display_name          => "Location of pig code",
  :description           => "Location of pig code",
  :default               => "/usr/lib/pig"

attribute "pig/install_url",
  :display_name          => "URL of pig release tarball",
  :description           => "URL of pig release tarball",
  :default               => "http://apache.mirrors.tds.net/pig/pig-0.9.1/pig-0.9.1.tar.gz"

attribute "pig/java_home",
  :display_name          => "JAVA_HOME environment variable to set for compilation",
  :description           => "JAVA_HOME environment variable to set for compilation. This should be the path to the 'jre' subdirectory of your Sun Java install (*not* OpenJDK).",
  :default               => "/usr/lib/jvm/java-6-sun/jre"

attribute "pig/extra_jars",
  :display_name          => "List of filenames for other jars to place within pig's purview",
  :description           => "List of filenames for other jars to place within pig's purview. FIXME: integration cookbook",
  :type                  => "array",
  :default               => ["/usr/lib/hbase/hbase-0.90.1-cdh3u0.jar", "/usr/lib/hbase/hbase-0.90.1-cdh3u0-tests.jar", "/usr/lib/zookeeper/zookeeper.jar"]

attribute "pig/extra_confs",
  :display_name          => "List of filenames for other systems' conf files to place within pig's purview",
  :description           => "List of filenames for other systems' conf files to place within pig's purview",
  :type                  => "array",
  :default               => ["/etc/hbase/conf/hbase-default.xml", "/etc/hbase/conf/hbase-site.xml"]

attribute "pig/combine_splits",
  :display_name          => "tunable: combine small files to reduce the number of map tasks",
  :description           => "Processing input (either user input or intermediate input) from multiple small files can be inefficient because a separate map has to be created for each file. Pig can now combined small files so that they are processed as a single map. combine_splits turns this on or off.",
  :default               => "true"
