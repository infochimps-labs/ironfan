maintainer       "Philip (flip) Kromer - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.2"

description      "Installs pig, a data analysis program for hadoop. It's like SQL but awesome and infinitely scalable."

depends          "java"
depends          "apt"
depends          "install_from"

recipe           "pig::default",                       "Base configuration for pig"
recipe           "pig::install_from_package",          "Installs pig from the cloudera package -- verified compatible, but on a slow update schedule."
recipe           "pig::install_from_release",          "Install From the release tarball."
recipe           "pig::integration",                   "Link in jars from hbase and zookeeper"
recipe           "pig::piggybank",                     "Compiles the Piggybank, a library of useful functions for pig"
recipe           "pig::add_cloudera_repo",             "Add Cloudera repo to package manager"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "apt/cloudera/force_distro",
  :display_name          => "Override the distro name apt uses to look up repos",
  :description           => "Typically, leave this blank. However if (as is the case in Nov 2011) you are on natty but Cloudera's repo only has packages up to maverick, use this to override.",
  :default               => ""

attribute "apt/cloudera/release_name",
  :display_name          => "Release identifier (eg cdh3u2) of the cloudera repo to use. See also hadoop/deb_version",
  :description           => "Release identifier (eg cdh3u2) of the cloudera repo to use. See also hadoop/deb_version",
  :default               => "cdh3u2"

attribute "pig/home_dir",
  :display_name          => "Location of pig code",
  :description           => "Location of pig code",
  :default               => "/usr/lib/pig"

attribute "pig/release_url",
  :display_name          => "URL of pig release tarball",
  :description           => "URL of pig release tarball",
  :default               => ":apache_mirror:/pig/pig-:version:/pig-:version:.tar.gz"

attribute "pig/combine_splits",
  :display_name          => "tunable: combine small files to reduce the number of map tasks",
  :description           => "Processing input (either user input or intermediate input) from multiple small files can be inefficient because a separate map has to be created for each file. Pig can now combined small files so that they are processed as a single map. combine_splits turns this on or off.",
  :default               => "true"

attribute "pig/version",
  :display_name          => "",
  :description           => "",
  :default               => "0.9.1"

attribute "java/java_home",
  :display_name          => "JAVA_HOME environment variable to set for compilation",
  :description           => "JAVA_HOME environment variable to set for compilation. This should be the path to the 'jre' subdirectory of your Sun Java install (*not* OpenJDK).",
  :default               => "/usr/lib/jvm/java-6-sun/jre"
