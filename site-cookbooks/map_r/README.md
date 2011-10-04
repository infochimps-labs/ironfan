## Description

Chef Recipes for installing [Map/R](http://www.mapr.com) on Ubuntu.

* Uses [Map/R installation guide](http://www.mapr.com/doc/display/MapR/M3+-+Ubuntu) as a baseline.
* Plays nicely with Amazon AWS and [Cluster Chef](http://github.com/infochimps/cluster_chef)

## Requirements

* 64-bit Ubuntu 9.04 or above
* RAM: 4 GB or more
* At least one free unmounted drive or partition, 50 GB or more
* At least 10 GB of free space on the operating system partition
* Sun Java JDK 6 (not JRE)

## Attributes


## Usage


### Topology

You can make your cluster rack-aware: see 'Topology' in attributes/map_r.rb


#### Topology in AWS for resizable clusters




