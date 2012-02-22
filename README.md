# Ironfan Core: Knife Tools and Core Models

Ironfan, the foundation of The Infochimps Platform, is an expressive toolset for constructing scalable, resilient architectures. It works in the cloud, in the data center, and on your laptop, and it makes your system diagram visible and inevitable. Inevitable systems coordinate automatically to interconnect, removing the hassle of manual configuration of connection points (and the associated danger of human error).
For more information about Ironfan and The Infochimps Platform, visit the [Infochimps Blog introducing the Infochimps Platform](http://blog.infochimps.com/2012/02/23/infochimps-platform/).

This repo implements:

* Core models to describe your system diagram with a clean, expressive domain-specific language
* Knife plugins to orchestrate clusters of machines using simple commands like `knife cluster launch`
* Logic to coordinate truth among chef server and cloud providers

## Getting Started

To jump right into using Ironfan, follow our [Installation Instructions](https://github.com/infochimps-labs/ironfan/wiki/INSTALL). For an explanatory tour, check out our [Hadoop Walkthrough](https://github.com/infochimps-labs/ironfan/wiki/INSTALL).  Please file all issues on [Ironfan issues](https://github.com/infochimps-labs/ironfan/issues).

## Index

The full Ironfan toolset:

###Core Tools:

* [ironfan-homebase](https://github.com/infochimps-labs/ironfan-homebase): Centralizes the cookbooks, roles and clusters. A solid foundation for any chef user.
* [ironfan gem](https://github.com/infochimps-labs/ironfan): The core Ironfan models, and Knife plugins to orchestrate machines and coordinate truth among your homebase, cloud and chef server. It comes with [ironfan-homebase](https://github.com/infochimps-labs/ironfan-homebase).
* [ironfan-pantry](https://github.com/infochimps-labs/ironfan-pantry): Our collection of industrial-strength, cloud-ready recipes for Hadoop, HBase, Cassandra, Elasticsearch, Zabbix and more. 
* [silverware cookbook](https://github.com/infochimps-labs/ironfan-pantry/tree/master/cookbooks/silverware): Helps you coordinate discovery of services ("list all the machines for `awesome_webapp`, that I might load balance them") and aspects ("list all components that write logs, that I might logrotate them, or that I might monitor the free space on their volumes"). Found within the [ironfan-pantry](https://github.com/infochimps-labs/ironfan-pantry).

###Core Documentation:

* [ironfan wiki](https://github.com/infochimps-labs/ironfan/wiki): High-level documentation and install instructions.
* [ironfan issues](https://github.com/infochimps-labs/ironfan/issues): Bugs or questions and feature requests for *any* part of the Ironfan toolset.
* [ironfan gem docs](http://rdoc.info/gems/ironfan): Rdoc docs for Ironfan.

## What is Ironfan? 
Ironfan is a systems provisioning and deployment tool. Ironfan automates not only machine configuration, but entire systems configuration to enable the entire Big Data stack, including tools for _data ingestion_, _scraping_, _storage_, _computation_, and _monitoring_.  

Ironfan builds on Chef, but is opinionated about its architecture, which allows broader integration between components. It assumes a source repository, a central Chef Server, and a modern POSIX-compliant operating system for a base image. Currently, it works best with Git, Amazon Web Services, Ubuntu 11.04, with exploration into other virtualization platforms (Vagrant, etc.) and operating systems (Centos, FreeSBD, etc) ongoing, both inside and outside of Infochimps.

To understand the Philosophy behind how we use Chef go [here](https://github.com/infochimps-labs/ironfan/wiki/Philosophy).



