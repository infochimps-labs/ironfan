maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures zookeeper"

depends          "java"
depends          "apt"
depends          "mountable_volumes"
depends          "provides_service"

recipe           "zookeeper::client",                  "Installs Zookeeper client libraries"
recipe           "zookeeper::default",                 "Base configuration for zookeeper"
recipe           "zookeeper::server",                  "Installs Zookeeper server, sets up and starts service"

%w[ debian ubuntu ].each do |os|
  supports os
end

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
