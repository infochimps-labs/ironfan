maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.3"

description      "Zookeeper, a distributed high-availability consistent datastore"

depends          "java"
depends          "apt"
depends          "runit"

depends          "volumes"
depends          "metachef"

recipe           "zookeeper::client",                  "Installs Zookeeper client libraries"
recipe           "zookeeper::default",                 "Base configuration for zookeeper"
recipe           "zookeeper::server",                  "Installs Zookeeper server, sets up and starts service"
recipe           "zookeeper::add_cloudera_repo",       "Add Cloudera repo to package manager"

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

attribute "groups/zookeeper/gid",
  :display_name          => "",
  :description           => "",
  :default               => "305"

attribute "zookeeper/data_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/zookeeper"

attribute "zookeeper/cluster_name",
  :display_name          => "",
  :description           => "",
  :default               => "cluster_name"

attribute "zookeeper/log_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/var/log/zookeeper"

attribute "zookeeper/max_client_connections",
  :display_name          => "",
  :description           => "",
  :default               => "30"

attribute "zookeeper/home_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/lib/zookeeper"

attribute "zookeeper/exported_jars",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/usr/lib/zookeeper/zookeeper.jar"]

attribute "zookeeper/conf_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/etc/zookeeper"

attribute "zookeeper/user",
  :display_name          => "",
  :description           => "",
  :default               => "zookeeper"

attribute "zookeeper/server/run_state",
  :display_name          => "",
  :description           => "",
  :default               => "stop"

attribute "users/zookeeper/uid",
  :display_name          => "",
  :description           => "",
  :default               => "305"
