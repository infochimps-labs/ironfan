Cookbook to install flume on a cluster.

Use flume::master to set up a master node. Use flume::node to set up a
physical node. Currently only one physical node per machines. 

Configure logical nodes with the logical_node resource - see the test_flow.rb 
recipe for an example. This is still somewhat experimental, and some features
will not work as well as they should until chef version 0.9.14 and others until
the next release of flume.

Coming soon flume::xxx_plugin.

#### Notes

This recipe relies on cluster_discovery_services to determine which nodes 
across the cluster act as flume masters, and which nodes provide zookeeper
servers.
