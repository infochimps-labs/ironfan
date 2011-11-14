@temujin9 has proposed, and it's a good propose, that there should exist such a thing as an 'integration cookbook'.

The hadoop_cluster cookbook should describe the hadoop_cluster, the ganglia cookbook ganglia, and the zookeeper cookbook zookeeper. Each should provide hooks that are neighborly but not exhibitionist, but should mind its own business.

The job of tying those components together should belong to a separate concern. It should know how and when to copy hbase jars into the pig home dir, or what cluster service_provide'r a redis client should reference.

## Practical implications

* I'm going to revert out the `node[:zookeeper][:cluster_name]` attributes -- services should always announce under their cluster.

* Until we figure out how and when to separate integrations, I'm going to isolate entanglements into their own recipes within cookbooks: so, the ganglia part of hadoop will become `ganglia_integration` or somesuch.

## Example integrations

### Copying jars

Pig needs jars from hbase and zookeeper.  They should announce they have jars; pig should announce its home directory;  the integration should decide how and where to copy the jars.

### Reference a service

Right now in several places we have attributes like `node[:zookeeper][:cluster_name]`, used to specify the cluster that provides_service zookeeper.

* Server recipes should never use `node[:zookeeper][:cluster_name]` -- they should always announce under their native cluster. (I'd kinda like to give `provides_service` some sugar to assume the cluster name, but need to find something backwards-compatible to use)

* Need to take a better survey of usage among clients to determine how to do this.

* cases:
  - hbase cookbook refs: hadoop, zookeeper, ganglia
  - flume cookbook refs: zookeeper, ganglia. 
  - flume nodes may reference several different flume provides_service'rs
  - API using two different elasticsearch clusters
  
### Logging, monitoring

* tell flume you have logs to pick up
* tell ganglia to monitor you

### Service Dashboard

Let everything with a dashboard say so, and then let one resource create a page that links to each.


________________________

These are still forming, ideas welcome.

