maintainer       "Chris Howe - Infochimps, Inc"
maintainer_email "coders@infochimps.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures zookeeper"



%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "groups/zookeeper/gid",
  :default               => "305",
  :display_name          => "",
  :description           => ""

attribute "zookeeper/data_dir",
  :default               => "/var/zookeeper",
  :display_name          => "",
  :description           => ""

attribute "zookeeper/cluster_name",
  :default               => "cluster_name",
  :display_name          => "",
  :description           => ""

attribute "zookeeper/log_dir",
  :default               => "/var/log/zookeeper",
  :display_name          => "",
  :description           => ""

attribute "zookeeper/max_client_connections",
  :default               => "30",
  :display_name          => "",
  :description           => ""
