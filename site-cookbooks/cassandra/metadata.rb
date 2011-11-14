maintainer       "Benjamin Black"
maintainer_email "b@b3k.us"
license          "Apache 2.0"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.2.2"

description      "Installs and configures the Cassandra distributed storage system"

depends          "java"
depends          "runit"
depends          "thrift"
depends          "provides_service"
depends          "iptables"

recipe           "cassandra::autoconf", "Automatically configure nodes from chef-server information."
recipe           "cassandra::ec2snitch", "Automatically configure properties snitch for clusters on EC2."
recipe           "cassandra::iptables", "Automatically configure iptables rules for cassandra."

%w[ debian ubuntu ].each do |os|
  supports os
end

attribute "cassandra/cluster_name",
  :display_name          => "Cassandra cluster name",
  :description           => "The name for the Cassandra cluster in which this node should participate.  The default is 'Test Cluster'.",
  :default               => "cluster_name"

attribute "cassandra/auto_bootstrap",
  :display_name          => "Cassandra automatic boostrap boolean",
  :description           => "Boolean indicating whether a node should automatically boostrap on startup.",
  :default               => "false"

attribute "cassandra/keyspaces",
  :display_name          => "Cassandra keyspaces",
  :description           => "Hash of keyspace definitions.",
  :type                  => "array",
  :default               => ""

attribute "cassandra/authenticator",
  :display_name          => "Cassandra authenticator",
  :description           => "The IAuthenticator to be used for access control.",
  :default               => "org.apache.cassandra.auth.AllowAllAuthenticator"

attribute "cassandra/partitioner",
  :default               => "org.apache.cassandra.dht.RandomPartitioner",
  :display_name          => "",
  :description           => ""

attribute "cassandra/initial_token",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "cassandra/commitlog_dir",
  :default               => "/mnt/cassandra/commitlog",
  :display_name          => "",
  :description           => ""

attribute "cassandra/data_file_dirs",
  :type                  => "array",
  :default               => ["/data/db/cassandra"],
  :display_name          => "",
  :description           => ""

attribute "cassandra/callout_location",
  :default               => "/var/lib/cassandra/callouts",
  :display_name          => "",
  :description           => ""

attribute "cassandra/staging_file_dir",
  :default               => "/var/lib/cassandra/staging",
  :display_name          => "",
  :description           => ""

attribute "cassandra/seeds",
  :type                  => "array",
  :default               => ["127.0.0.1"],
  :display_name          => "",
  :description           => ""

attribute "cassandra/rpc_timeout",
  :default               => "5000",
  :display_name          => "",
  :description           => ""

attribute "cassandra/commitlog_rotation_threshold",
  :default               => "128",
  :display_name          => "",
  :description           => ""

attribute "cassandra/listen_addr",
  :default               => "localhost",
  :display_name          => "",
  :description           => ""

attribute "cassandra/storage_port",
  :default               => "7000",
  :display_name          => "",
  :description           => ""

attribute "cassandra/rpc_addr",
  :default               => "localhost",
  :display_name          => "",
  :description           => ""

attribute "cassandra/rpc_port",
  :default               => "9160",
  :display_name          => "",
  :description           => ""

attribute "cassandra/thrift_framed_transport",
  :default               => "15",
  :display_name          => "",
  :description           => ""

attribute "cassandra/disk_access_mode",
  :default               => "auto",
  :display_name          => "",
  :description           => ""

attribute "cassandra/sliced_buffer_size",
  :default               => "64",
  :display_name          => "",
  :description           => ""

attribute "cassandra/flush_data_buffer_size",
  :default               => "32",
  :display_name          => "",
  :description           => ""

attribute "cassandra/flush_index_buffer_size",
  :default               => "8",
  :display_name          => "",
  :description           => ""

attribute "cassandra/column_index_size",
  :default               => "64",
  :display_name          => "",
  :description           => ""

attribute "cassandra/memtable_throughput",
  :default               => "64",
  :display_name          => "",
  :description           => ""

attribute "cassandra/binary_memtable_throughput",
  :default               => "256",
  :display_name          => "",
  :description           => ""

attribute "cassandra/memtable_ops",
  :default               => "0.3",
  :display_name          => "",
  :description           => ""

attribute "cassandra/memtable_flush_after",
  :default               => "60",
  :display_name          => "",
  :description           => ""

attribute "cassandra/concurrent_reads",
  :default               => "8",
  :display_name          => "",
  :description           => ""

attribute "cassandra/concurrent_writes",
  :default               => "32",
  :display_name          => "",
  :description           => ""

attribute "cassandra/commitlog_sync",
  :default               => "periodic",
  :display_name          => "",
  :description           => ""

attribute "cassandra/commitlog_sync_period",
  :default               => "10000",
  :display_name          => "",
  :description           => ""

attribute "cassandra/gc_grace",
  :default               => "864000",
  :display_name          => "",
  :description           => ""

attribute "cassandra/public_access",
  :display_name          => "Public access",
  :description           => "If the node is on a cloud server with public and private IP addresses and public_access is true, then Thrift will be bound on the public IP address.  Disabled by default.",
  :default               => ""

attribute "cassandra/cassandra_home",
  :default               => "/usr/local/share/cassandra",
  :display_name          => "",
  :description           => ""

attribute "cassandra/cassandra_conf",
  :default               => "/etc/cassandra",
  :display_name          => "",
  :description           => ""

attribute "cassandra/cassandra_user",
  :default               => "cassandra",
  :display_name          => "",
  :description           => ""

attribute "cassandra/saved_caches_dir",
  :default               => "/var/lib/cassandra/saved_caches",
  :display_name          => "",
  :description           => ""

attribute "cassandra/jmx_port",
  :default               => "12345",
  :display_name          => "",
  :description           => ""

attribute "cassandra/authority",
  :default               => "org.apache.cassandra.auth.AllowAllAuthority",
  :display_name          => "",
  :description           => ""

attribute "cassandra/hinted_handoff_enabled",
  :default               => "true",
  :display_name          => "",
  :description           => ""

attribute "cassandra/max_hint_window_in_ms",
  :default               => "3600000",
  :display_name          => "",
  :description           => ""

attribute "cassandra/hinted_handoff_throttle_delay_in_ms",
  :default               => "50",
  :display_name          => "",
  :description           => ""

attribute "cassandra/endpoint_snitch",
  :default               => "org.apache.cassandra.locator.SimpleSnitch",
  :display_name          => "",
  :description           => ""

attribute "cassandra/dynamic_snitch",
  :default               => "true",
  :display_name          => "",
  :description           => ""

attribute "cassandra/java_min_heap",
  :default               => "128M",
  :display_name          => "",
  :description           => ""

attribute "cassandra/java_max_heap",
  :default               => "1650M",
  :display_name          => "",
  :description           => ""

attribute "cassandra/java_eden_heap",
  :default               => "1500M",
  :display_name          => "",
  :description           => ""

attribute "cassandra/memtable_flush_writers",
  :default               => "1",
  :display_name          => "",
  :description           => ""

attribute "cassandra/thrift_max_message_length",
  :default               => "16",
  :display_name          => "",
  :description           => ""

attribute "cassandra/incremental_backups",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "cassandra/snapshot_before_compaction",
  :display_name          => "",
  :description           => "",
  :default               => ""

attribute "cassandra/in_memory_compaction_limit",
  :default               => "64",
  :display_name          => "",
  :description           => ""

attribute "cassandra/compaction_preheat_key_cache",
  :default               => "true",
  :display_name          => "",
  :description           => ""

attribute "cassandra/flush_largest_memtables_at",
  :default               => "0.75",
  :display_name          => "",
  :description           => ""

attribute "cassandra/reduce_cache_sizes_at",
  :default               => "0.85",
  :display_name          => "",
  :description           => ""

attribute "cassandra/reduce_cache_capacity_to",
  :default               => "0.6",
  :display_name          => "",
  :description           => ""

attribute "cassandra/rpc_timeout_in_ms",
  :default               => "10000",
  :display_name          => "",
  :description           => ""

attribute "cassandra/rpc_keepalive",
  :default               => "false",
  :display_name          => "",
  :description           => ""

attribute "cassandra/phi_convict_threshold",
  :default               => "8",
  :display_name          => "",
  :description           => ""

attribute "cassandra/request_scheduler",
  :default               => "org.apache.cassandra.scheduler.NoScheduler",
  :display_name          => "",
  :description           => ""

attribute "cassandra/throttle_limit",
  :default               => "80",
  :display_name          => "",
  :description           => ""

attribute "cassandra/request_scheduler_id",
  :default               => "keyspace",
  :display_name          => "",
  :description           => ""

attribute "cassandra/install_url",
  :default               => "http://www.eng.lsu.edu/mirrors/apache/cassandra/0.7.7/apache-cassandra-0.7.7-bin.tar.gz",
  :display_name          => "",
  :description           => ""

attribute "cassandra/git_repo",
  :default               => "git://git.apache.org/cassandra.git",
  :display_name          => "",
  :description           => ""

attribute "cassandra/git_revision",
  :default               => "cdd239dcf82ab52cb840e070fc01135efb512799",
  :display_name          => "",
  :description           => ""

attribute "cassandra/jna_deb_amd64_url",
  :default               => "http://debian.riptano.com/maverick/pool/libjna-java_3.2.7-0~nmu.2_amd64.deb",
  :display_name          => "",
  :description           => ""

attribute "cassandra/mx4j_url",
  :default               => "http://downloads.sourceforge.net/project/mx4j/MX4J%20Binary/3.0.2/mx4j-3.0.2.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fmx4j%2Ffiles%2F&ts=1303407638&use_mirror=iweb",
  :display_name          => "",
  :description           => ""

attribute "cassandra/mx4j_listen_addr",
  :default               => "127.0.0.1",
  :display_name          => "",
  :description           => ""

attribute "cassandra/mx4j_listen_port",
  :default               => "8081",
  :display_name          => "",
  :description           => ""
