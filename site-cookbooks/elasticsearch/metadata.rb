maintainer       "GoTime, modifications by Infochimps"
maintainer_email "ops@gotime.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures elasticsearch"

depends          "java"
depends          "aws"
depends          "runit"
depends          "mountable_volumes"
depends          "provides_service"
depends          "nginx"

recipe           "elasticsearch::autoconf",            "Autoconf"
recipe           "elasticsearch::build_raid",          "Build Raid"
recipe           "elasticsearch::client",              "Client"
recipe           "elasticsearch::default",             "Base configuration for elasticsearch"
recipe           "elasticsearch::http",                "Http"
recipe           "elasticsearch::install_from_git",    "Install From Git"
recipe           "elasticsearch::install_from_release", "Install From Release"
recipe           "elasticsearch::install_plugins",     "Install Plugins"
recipe           "elasticsearch::server",              "Server"

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "elasticsearch/version",
  :display_name          => "",
  :description           => "",
  :default               => "0.13.1"

attribute "elasticsearch/cluster_name",
  :display_name          => "",
  :description           => "",
  :default               => "default"

attribute "elasticsearch/install_dir",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/local/share/elasticsearch"

attribute "elasticsearch/data_root",
  :display_name          => "",
  :description           => "",
  :default               => "/mnt/elasticsearch"

attribute "elasticsearch/java_home",
  :display_name          => "",
  :description           => "",
  :default               => "/usr/lib/jvm/java-6-sun/jre"

attribute "elasticsearch/git_repo",
  :display_name          => "",
  :description           => "",
  :default               => "https://github.com/elasticsearch/elasticsearch.git"

attribute "elasticsearch/java_heap_size_max",
  :display_name          => "",
  :description           => "",
  :default               => "1000"

attribute "elasticsearch/ulimit_mlock",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "elasticsearch/default_replicas",
  :display_name          => "",
  :description           => "",
  :default               => "1"

attribute "elasticsearch/default_shards",
  :display_name          => "",
  :description           => "",
  :default               => "6"

attribute "elasticsearch/flush_threshold",
  :display_name          => "",
  :description           => "",
  :default               => "5000"

attribute "elasticsearch/index_buffer_size",
  :display_name          => "",
  :description           => "",
  :default               => "10%"

attribute "elasticsearch/merge_factor",
  :display_name          => "",
  :description           => "",
  :default               => "10"

attribute "elasticsearch/max_thread_count",
  :display_name          => "",
  :description           => "",
  :default               => "4"

attribute "elasticsearch/term_index_interval",
  :display_name          => "",
  :description           => "",
  :default               => "128"

attribute "elasticsearch/refresh_interval",
  :display_name          => "",
  :description           => "",
  :default               => "1s"

attribute "elasticsearch/snapshot_interval",
  :display_name          => "",
  :description           => "",
  :default               => "-1"

attribute "elasticsearch/snapshot_on_close",
  :display_name          => "",
  :description           => "",
  :default               => "false"

attribute "elasticsearch/seeds",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "elasticsearch/recovery_after_nodes",
  :display_name          => "",
  :description           => "",
  :default               => "2"

attribute "elasticsearch/recovery_after_time",
  :display_name          => "",
  :description           => "",
  :default               => "5m"

attribute "elasticsearch/expected_nodes",
  :display_name          => "",
  :description           => "",
  :default               => "2"

attribute "elasticsearch/fd_ping_interval",
  :display_name          => "",
  :description           => "",
  :default               => "1s"

attribute "elasticsearch/fd_ping_timeout",
  :display_name          => "",
  :description           => "",
  :default               => "30s"

attribute "elasticsearch/fd_ping_retries",
  :display_name          => "",
  :description           => "",
  :default               => "3"

attribute "elasticsearch/jmx_port",
  :display_name          => "",
  :description           => "",
  :default               => "9400-9500"

attribute "elasticsearch/log_level/default",
  :display_name          => "",
  :description           => "",
  :default               => "DEBUG"

attribute "elasticsearch/log_level/index_store",
  :display_name          => "",
  :description           => "",
  :default               => "INFO"

attribute "elasticsearch/log_level/action_shard",
  :display_name          => "",
  :description           => "",
  :default               => "INFO"

attribute "elasticsearch/log_level/cluster_service",
  :display_name          => "",
  :description           => "",
  :default               => "INFO"

attribute "elasticsearch/raid/devices",
  :display_name          => "",
  :description           => "",
  :type                  => "array",
  :default               => ["/dev/sdb", "/dev/sdc", "/dev/sdd", "/dev/sde"]

attribute "elasticsearch/raid/use_raid",
  :display_name          => "",
  :description           => "",
  :default               => "true"
