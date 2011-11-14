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
