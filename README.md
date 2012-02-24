# Ironfan Core: Knife Tools and Core Models

Ironfan, the foundation of The Infochimps Platform, is an expressive toolset for constructing scalable, resilient architectures. It works in the cloud, in the data center, and on your laptop, and it makes your system diagram visible and inevitable. Inevitable systems coordinate automatically to interconnect, removing the hassle of manual configuration of connection points (and the associated danger of human error).
For more information about Ironfan and The Infochimps Platform, visit the [Infochimps Blog introducing the Infochimps Platform](http://blog.infochimps.com/2012/02/22/infochimps-platform/).

This repo implements:

* Core models to describe your system diagram with a clean, expressive domain-specific language
* Knife plugins to orchestrate clusters of machines using simple commands like `knife cluster launch`
* Logic to coordinate truth among chef server and cloud providers

## Getting Started

To jump right into using Ironfan, follow our [Installation Instructions](https://github.com/infochimps-labs/ironfan/wiki/INSTALL). For an explanatory tour, check out our [Hadoop Walkthrough](https://github.com/infochimps-labs/ironfan/wiki/INSTALL).  Please file all issues on [Ironfan issues](https://github.com/infochimps-labs/ironfan/issues).

### Tools

Ironfan consists of the following Toolset:

* [ironfan-homebase](https://github.com/infochimps-labs/ironfan-homebase): centralizes the cookbooks, roles and clusters. A solid foundation for any chef user.
* [ironfan gem](https://github.com/infochimps-labs/ironfan):
  - core models to describe your system diagram with a clean, expressive domain-specific language
  - knife plugins to orchestrate clusters of machines using simple commands like `knife cluster launch`
  - logic to coordinate truth among chef server and cloud providers.
* [ironfan-pantry](https://github.com/infochimps-labs/ironfan-pantry): Our collection of industrial-strength, cloud-ready recipes for Hadoop, HBase, Cassandra, Elasticsearch, Zabbix and more.
* [silverware cookbook](https://github.com/infochimps-labs/ironfan-homebase/tree/master/cookbooks/silverware): coordinate discovery of services ("list all the machines for `awesome_webapp`, that I might load balance them") and aspects ("list all components that write logs, that I might logrotate them, or that I might monitor the free space on their volumes".

### Documentation

* [ironfan wiki](https://github.com/infochimps-labs/ironfan/wiki): high-level documentation and install instructions
* [Index of wiki pages](https://github.com/infochimps-labs/ironfan/wiki/_pages)
* [ironfan issues](https://github.com/infochimps-labs/ironfan/issues): bugs, questions and feature requests for *any* part of the ironfan toolset.
* [ironfan gem docs](http://rdoc.info/gems/ironfan): rdoc docs for ironfan
* Ironfan powers the [Infochimps Platform](http://www.infochimps.com/how-it-works), our scalable enterprise big data platform. Ironfan Enterprise adds zero-configuration logging, monitoring and a compelling UI.
* [Ironfan Screencast](http://bit.ly/ironfan-hadoop-in-20-minutes) -- build a Hadoop cluster from scratch in 20 minutes.

### The Ironfan Way

* [Core Concepts](core_concepts)     -- Components, Announcements, Amenities and more.
* [Philosophy](philosophy)            -- best practices and lessons learned
* [Style Guide](style_guide)         -- common attribute names, how and when to include other cookbooks, and more
* [Homebase Layout](homebase-layout) -- how this homebase is organized, and why
