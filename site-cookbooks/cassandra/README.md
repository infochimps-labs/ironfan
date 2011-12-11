# cassandra chef cookbook

Installs and configures the Cassandra distributed storage system

## Overview

# Cassandra  Cluster

Cookbook based on Benjamin Black's (<b@b3k.us>) -- original at http://github.com/b/cookbooks/tree/cassandra/cassandra/

Modified to use `metachef` discovery and options preparation.

## Attributes

* `[:cassandra][:cluster_name]`       - Cassandra cluster name (default: "cluster_name")
  - The name for the Cassandra cluster in which this node should participate.  The default is 'Test Cluster'.
* `[:cassandra][:home_dir]`           -  (default: "/usr/local/share/cassandra")
* `[:cassandra][:conf_dir]`           -  (default: "/etc/cassandra")
* `[:cassandra][:commitlog_dir]`      -  (default: "/mnt/cassandra/commitlog")
* `[:cassandra][:data_dirs]`          - 
* `[:cassandra][:saved_caches_dir]`   -  (default: "/var/lib/cassandra/saved_caches")
* `[:cassandra][:user]`               -  (default: "cassandra")
* `[:cassandra][:listen_addr]`        -  (default: "localhost")
* `[:cassandra][:seeds]`              - 
* `[:cassandra][:rpc_addr]`           -  (default: "localhost")
* `[:cassandra][:rpc_port]`           -  (default: "9160")
* `[:cassandra][:storage_port]`       -  (default: "7000")
* `[:cassandra][:jmx_dash_port]`           -  (default: "12345")
* `[:cassandra][:mx4j_port]`   -  (default: "8081")
* `[:cassandra][:mx4j_addr]`   -  (default: "127.0.0.1")
* `[:cassandra][:release_url]`        -  (default: ":apache_mirror:/cassandra/:version:/apache-cassandra-:version:-bin.tar.gz")
* `[:cassandra][:git_repo]`           -  (default: "git://git.apache.org/cassandra.git")
* `[:cassandra][:git_revision]`       -  (default: "cdd239dcf82ab52cb840e070fc01135efb512799")
* `[:cassandra][:jna_deb_amd64_url]`  -  (default: "http://debian.riptano.com/maverick/pool/libjna-java_3.2.7-0~nmu.2_amd64.deb")
* `[:cassandra][:mx4j_url]`           -  (default: "http://downloads.sourceforge.net/project/mx4j/MX4J%20Binary/3.0.2/mx4j-3.0.2.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fmx4j%2Ffiles%2F&ts=1303407638&use_mirror=iweb")
* `[:cassandra][:auto_bootstrap]`     - Cassandra automatic boostrap boolean (default: "false")
  - Boolean indicating whether a node should automatically boostrap on startup.
* `[:cassandra][:keyspaces]`          - Cassandra keyspaces
  - Hash of keyspace definitions.
* `[:cassandra][:authenticator]`      - Cassandra authenticator (default: "org.apache.cassandra.auth.AllowAllAuthenticator")
  - The IAuthenticator to be used for access control.
* `[:cassandra][:partitioner]`        -  (default: "org.apache.cassandra.dht.RandomPartitioner")
* `[:cassandra][:initial_token]`      - 
* `[:cassandra][:rpc_timeout]`        -  (default: "5000")
* `[:cassandra][:commitlog_rotation_threshold]` -  (default: "128")
* `[:cassandra][:thrift_framed_transport]` -  (default: "15")
* `[:cassandra][:disk_access_mode]`   -  (default: "auto")
* `[:cassandra][:sliced_buffer_size]` -  (default: "64")
* `[:cassandra][:flush_data_buffer_size]` -  (default: "32")
* `[:cassandra][:flush_index_buffer_size]` -  (default: "8")
* `[:cassandra][:column_index_size]`  -  (default: "64")
* `[:cassandra][:memtable_throughput]` -  (default: "64")
* `[:cassandra][:binary_memtable_throughput]` -  (default: "256")
* `[:cassandra][:memtable_ops]`       -  (default: "0.3")
* `[:cassandra][:memtable_flush_after]` -  (default: "60")
* `[:cassandra][:concurrent_reads]`   -  (default: "8")
* `[:cassandra][:concurrent_writes]`  -  (default: "32")
* `[:cassandra][:commitlog_sync]`     -  (default: "periodic")
* `[:cassandra][:commitlog_sync_period]` -  (default: "10000")
* `[:cassandra][:gc_grace]`           -  (default: "864000")
* `[:cassandra][:authority]`          -  (default: "org.apache.cassandra.auth.AllowAllAuthority")
* `[:cassandra][:hinted_handoff_enabled]` -  (default: "true")
* `[:cassandra][:max_hint_window_in_ms]` -  (default: "3600000")
* `[:cassandra][:hinted_handoff_delay_ms]` -  (default: "50")
* `[:cassandra][:endpoint_snitch]`    -  (default: "org.apache.cassandra.locator.SimpleSnitch")
* `[:cassandra][:dynamic_snitch]`     -  (default: "true")
* `[:cassandra][:java_heap_size_min]` -  (default: "128M")
* `[:cassandra][:java_heap_size_max]` -  (default: "1650M")
* `[:cassandra][:java_heap_size_eden]` -  (default: "1500M")
* `[:cassandra][:memtable_flush_writers]` -  (default: "1")
* `[:cassandra][:thrift_max_message_length]` -  (default: "16")
* `[:cassandra][:incremental_backups]` - 
* `[:cassandra][:snapshot_before_compaction]` - 
* `[:cassandra][:in_memory_compaction_limit]` -  (default: "64")
* `[:cassandra][:compaction_preheat_key_cache]` -  (default: "true")
* `[:cassandra][:flush_largest_memtables_at]` -  (default: "0.75")
* `[:cassandra][:reduce_cache_sizes_at]` -  (default: "0.85")
* `[:cassandra][:reduce_cache_capacity_to]` -  (default: "0.6")
* `[:cassandra][:rpc_timeout_in_ms]`  -  (default: "10000")
* `[:cassandra][:rpc_keepalive]`      -  (default: "false")
* `[:cassandra][:phi_convict_threshold]` -  (default: "8")
* `[:cassandra][:request_scheduler]`  -  (default: "org.apache.cassandra.scheduler.NoScheduler")
* `[:cassandra][:throttle_limit]`     -  (default: "80")
* `[:cassandra][:request_scheduler_id]` -  (default: "keyspace")
* `[:cassandra][:log_dir]`            -  (default: "/var/log/cassandra")
* `[:cassandra][:lib_dir]`            -  (default: "/var/lib/cassandra")
* `[:cassandra][:pid_dir]`            -  (default: "/var/run/cassandra")
* `[:cassandra][:group]`              -  (default: "nogroup")
* `[:cassandra][:version]`            -  (default: "0.7.10")
* `[:cassandra][:mx4j_version]`       -  (default: "3.0.2")
* `[:cassandra][:mx4j_release_url]`   -  (default: "http://downloads.sourceforge.net/project/mx4j/MX4J%20Binary/x.x/mx4j-x.x.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fmx4j%2Ffiles%2F&ts=1303407638&use_mirror=iweb")
* `[:users][:cassandra][:uid]`        -  (default: "330")
* `[:users][:cassandra][:gid]`        -  (default: "330")

## Recipes 

* `authentication`           - Authentication
* `autoconf`                 - Automatically configure nodes from chef-server information.
* `bintools`                 - Bintools
* `client`                   - Client
* `default`                  - Base configuration for cassandra
* `ec2snitch`                - Automatically configure properties snitch for clusters on EC2.
* `install_from_git`         - Install From Git
* `install_from_package`     - Install From Package
* `install_from_release`     - Install From Release
* `iptables`                 - Automatically configure iptables rules for cassandra.
* `jna_support`              - Jna Support
* `mx4j`                     - Mx4j
* `server`                   - Server
## Integration

Supports platforms: debian and ubuntu

Cookbook dependencies:
* java
* runit
* thrift
* volumes
* provides_service
* metachef
* iptables


## License and Author

Author::                Benjamin Black (<b@b3k.us>)
Copyright::             2011, Benjamin Black

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

> readme generated by [cluster_chef](http://github.com/infochimps/cluster_chef)'s cookbook_munger
