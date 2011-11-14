maintainer       "GoTime, modifications by Infochimps"
maintainer_email "ops@gotime.com"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "3.0.0"

description      "Installs/Configures elasticsearch"

depends          "java"
depends          "runit"
depends          "aws"
depends          "provides_service"


%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "elasticsearch/version",
  :default               => "0.13.1",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/cluster_name",
  :default               => "default",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/install_dir",
  :default               => "/usr/local/share/elasticsearch",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/data_root",
  :default               => "/mnt/elasticsearch",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/java_home",
  :default               => "/usr/lib/jvm/java-6-sun/jre",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/git_repo",
  :default               => "https://github.com/elasticsearch/elasticsearch.git",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/heap_size",
  :default               => "1000",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/ulimit_mlock",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "elasticsearch/default_replicas",
  :default               => "1",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/default_shards",
  :default               => "6",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/flush_threshold",
  :default               => "5000",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/index_buffer_size",
  :default               => "10%",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/merge_factor",
  :default               => "10",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/max_thread_count",
  :default               => "4",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/term_index_interval",
  :default               => "128",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/refresh_interval",
  :default               => "1s",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/snapshot_interval",
  :default               => "-1",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/snapshot_on_close",
  :default               => "false",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/seeds",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "elasticsearch/recovery_after_nodes",
  :default               => "2",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/recovery_after_time",
  :default               => "5m",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/expected_nodes",
  :default               => "2",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/fd_ping_interval",
  :default               => "1s",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/fd_ping_timeout",
  :default               => "30s",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/fd_ping_retries",
  :default               => "3",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/jmx_port",
  :default               => "9400-9500",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/log_level/default",
  :default               => "DEBUG",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/log_level/index_store",
  :default               => "INFO",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/log_level/action_shard",
  :default               => "INFO",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/log_level/cluster_service",
  :default               => "INFO",
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/raid/devices",
  :type                  => "array",
  :default               => ["/dev/sdb", "/dev/sdc", "/dev/sdd", "/dev/sde"],
  :display_name          => "",
  :description           => ""

attribute "elasticsearch/raid/use_raid",
  :default               => "true",
  :display_name          => "",
  :description           => ""
