# cassandra chef cookbook

Installs and configures the Cassandra distributed storage system

## Overview

# Cassandra <3 Hadoop 

Cookbook based on Benjamin Black's (<b@b3k.us>) -- original at http://github.com/b/cookbooks/tree/cassandra/cassandra/

Modified to use `provides_service` and to play nice with hadoop_cluster.

## About the machine configurations

Please know that the configuration settings for cassandra are

  NOT TO BE DIDDLED LIGHTLY!!!!

Unless your settings well fit one of the scenarios below, you should leave them
at the defaults.

In all of the above:

* Data to be stored will be many times larger than available memory
* Writes will be **extremely** bursty, and may come from 30 or more processes on 20 or more nodes
* Desirable if the cluster allows massive-scale writes at low consistency levels (ZERO, ANY or ONE)

## Scenario I: Dedicated Cassandra cluster, high-memory nodes

#### Nodes:

* AWS m2.xlarge instances ($0.50 / hr)
* 17.7 GB ram, 64-bit, 2 cores
* Moderate IO rate
* single 420 GB local drive mounted as /mnt, ext3-formatted
* Two EBS volumes, mounted as /ebs1 and /ebs2, XFS-formatted
* No swap
* Overcommit enabled
* Ubuntu lucid

#### Cluster:

* 10 machines
* Completely dedicated to cassandra
* Much more data stored than memory available (say, 2TB with 2x replication + overhead)
* Load is constant reads and writes, with occasional need to cross-load from hadoop cluster
* Optimize for random reads
* Must not fall down when hadoop cluster attacks it.

#### Proposed:

* Commitlog goes to the ephemeral partition
* Data is stored on EBS volumes
* ?? Initial java heap set to XXXX
* ?? Increase concurrent reads and concurrent writes

### Scenario Ia: Dedicated Cassandra cluster, medium-memory nodes

Side question: what are the tradeoffs to consider to choose between the same $$ amount being spent on 

* AWS m1.large instances ($0.34 / hr)
* 7.5 GB ram, 64-bit, 2 cores, CPU is 35% slower (4 bogoflops vs 6.5 bogoflops) than the m2.xlarge
* High IO rate
* single 850 GB local drive mounted as /mnt, ext3-formatted

## Scenario II: Cassandra nodes and Hadoop workers on same machines

#### Each node:

* AWS m2.xlarge instances ($0.50 / hr)
* 17.7 GB ram, 64-bit, 2 cores
* Moderate IO
* single 420 GB local drive mounted as /mnt, ext3-formatted
* Two EBS volumes, mounted as /ebs1 and /ebs2, XFS-formatted
* No swap
* Overcommit enabled
* Ubuntu lucid

#### Cluster:

* 10-30 machines
* ?? allocate non-OS machine resources as 1/3 to cassandra 2/3 to hadoop
* Much more data stored (say, 2TB with 2x replication + overhead) than memory available
* Load is usually bulk reads and bulk writes
* No need to optimize for random reads

#### Proposed:

* Commitlog goes to the ephemeral partition
* Data is stored on EBS volumes
* Initial java heap set to XXXX

## Scenario III: Just screwing around with cassandra: 32-bit, much-too-little-memory nodes

* AWS m1.small instances ($0.08 / hr)
* EBS-backed, so the root partition is VERY SLOW
* 1.7 GB ram, 32-bit, 1 core
* single 160 GB local drive mounted as /mnt, ext3-formatted
* Commitlog and database both go to the same local (ephemeral) partition
* Moderate IO
* No swap
* Overcommit enabled
* Ubuntu lucid

## Attributes

* `[:cassandra][:cluster_name]`       - Cassandra cluster name (default: "cluster_name")
  The name for the Cassandra cluster in which this node should participate.  The default is 'Test Cluster'.
* `[:cassandra][:auto_bootstrap]`     - Cassandra automatic boostrap boolean (default: "false")
  Boolean indicating whether a node should automatically boostrap on startup.
* `[:cassandra][:keyspaces]`          - Cassandra keyspaces
  Hash of keyspace definitions.
* `[:cassandra][:authenticator]`      - Cassandra authenticator (default: "org.apache.cassandra.auth.AllowAllAuthenticator")
  The IAuthenticator to be used for access control.
* `[:cassandra][:partitioner]`        -  (default: "org.apache.cassandra.dht.RandomPartitioner")
* `[:cassandra][:initial_token]`      - 
* `[:cassandra][:commitlog_dir]`      -  (default: "/mnt/cassandra/commitlog")
* `[:cassandra][:data_file_dirs]`     - 
* `[:cassandra][:callout_location]`   -  (default: "/var/lib/cassandra/callouts")
* `[:cassandra][:staging_file_dir]`   -  (default: "/var/lib/cassandra/staging")
* `[:cassandra][:seeds]`              - 
* `[:cassandra][:rpc_timeout]`        -  (default: "5000")
* `[:cassandra][:commitlog_rotation_threshold]` -  (default: "128")
* `[:cassandra][:listen_addr]`        -  (default: "localhost")
* `[:cassandra][:storage_port]`       -  (default: "7000")
* `[:cassandra][:rpc_addr]`           -  (default: "localhost")
* `[:cassandra][:rpc_port]`           -  (default: "9160")
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
* `[:cassandra][:public_access]`      - Public access
  If the node is on a cloud server with public and private IP addresses and public_access is true, then Thrift will be bound on the public IP address.  Disabled by default.
* `[:cassandra][:cassandra_home]`     -  (default: "/usr/local/share/cassandra")
* `[:cassandra][:cassandra_conf]`     -  (default: "/etc/cassandra")
* `[:cassandra][:cassandra_user]`     -  (default: "cassandra")
* `[:cassandra][:saved_caches_dir]`   -  (default: "/var/lib/cassandra/saved_caches")
* `[:cassandra][:jmx_port]`           -  (default: "12345")
* `[:cassandra][:authority]`          -  (default: "org.apache.cassandra.auth.AllowAllAuthority")
* `[:cassandra][:hinted_handoff_enabled]` -  (default: "true")
* `[:cassandra][:max_hint_window_in_ms]` -  (default: "3600000")
* `[:cassandra][:hinted_handoff_throttle_delay_in_ms]` -  (default: "50")
* `[:cassandra][:endpoint_snitch]`    -  (default: "org.apache.cassandra.locator.SimpleSnitch")
* `[:cassandra][:dynamic_snitch]`     -  (default: "true")
* `[:cassandra][:java_min_heap]`      -  (default: "128M")
* `[:cassandra][:java_max_heap]`      -  (default: "1650M")
* `[:cassandra][:java_eden_heap]`     -  (default: "1500M")
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
* `[:cassandra][:install_url]`        -  (default: "http://www.eng.lsu.edu/mirrors/apache/cassandra/0.7.7/apache-cassandra-0.7.7-bin.tar.gz")
* `[:cassandra][:git_repo]`           -  (default: "git://git.apache.org/cassandra.git")
* `[:cassandra][:git_revision]`       -  (default: "cdd239dcf82ab52cb840e070fc01135efb512799")
* `[:cassandra][:jna_deb_amd64_url]`  -  (default: "http://debian.riptano.com/maverick/pool/libjna-java_3.2.7-0~nmu.2_amd64.deb")
* `[:cassandra][:mx4j_url]`           -  (default: "http://downloads.sourceforge.net/project/mx4j/MX4J%20Binary/3.0.2/mx4j-3.0.2.zip?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fmx4j%2Ffiles%2F&ts=1303407638&use_mirror=iweb")
* `[:cassandra][:mx4j_listen_addr]`   -  (default: "127.0.0.1")
* `[:cassandra][:mx4j_listen_port]`   -  (default: "8081")

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
* mountable_volumes
* provides_service
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
