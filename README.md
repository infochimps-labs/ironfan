# Ironfan Core: knife tools and core models

Ironfan is an expressive toolset for scalable, resilient architectures. It enables "Infrastructure as Code", allowing you to describe and orchestrate systems that work in the cloud, in the data center, and on your laptop, makes your system diagram visible and inevitable.

This repo implements

* core models to describe your system diagram with a clean, expressive domain-specific language
* knife plugins to orchestrate clusters of machines using simple commands like `knife cluster launch`
* logic to coordinate truth among chef server and cloud providers.

## Getting Started

To jump right into using Ironfan, follow our [installation instructions](https://github.com/infochimps-labs/ironfan/wiki/INSTALL). For an explanatory tour, check out our [Hadoop walkthrough](https://github.com/infochimps-labs/ironfan/wiki/INSTALL).  Please file all issues on [ironfan issues](https://github.com/infochimps-labs/ironfan/issues).

## Index

ironfan core works together with the full ironfan toolset:

* [ironfan-homebase](https://github.com/infochimps-labs/ironfan-homebase): centralizes the cookbooks, roles and clusters. A solid foundation for any chef user.
* [ironfan gem](https://github.com/infochimps-labs/ironfan): core ironfan models, and knife plugins to orchestrate machines and coordinate truth among you homebase, cloud and chef server.
* [ironfan-pantry](https://github.com/infochimps-labs/ironfan-pantry): Our collection of industrial-strength, cloud-ready recipes for Hadoop, HBase, Cassandra, Elasticsearch, Zabbix and more.
* [silverware cookbook](https://github.com/infochimps-labs/ironfan-pantry/tree/master/cookbooks/silverware): coordinate discovery of services ("list all the machines for `awesome_webapp`, that I might load balance them") and aspects ("list all components that write logs, that I might logrotate them, or that I might monitor the free space on their volumes".
* [ironfan-ci](https://github.com/infochimps-labs/ironfan-ci): Continuous integration testing of not just your cookbooks but your *architecture*.

* [ironfan wiki](https://github.com/infochimps-labs/ironfan/wiki): high-level documentation and install instructions
* [ironfan issues](https://github.com/infochimps-labs/ironfan/issues): bugs, questions and feature requests for *any* part of the ironfan toolset.
* [ironfan gem docs](http://rdoc.info/gems/ironfan): rdoc docs for ironfan

## Philosophy

Some general principles of how we use chef.

* *Chef server is never the repository of truth* -- it only mirrors the truth. A file is tangible and immediate to access.
* Specifically, we want truth to live in the git repo, and be enforced by the chef server.  This means that everything is versioned, documented and exchangeable. *There is no truth but git, and chef is its messenger*.
* *Systems, services and significant modifications cluster should be obvious from the `clusters` file*.  I don't want to have to bounce around nine different files to find out which thing installed a redis:server. The existence of anything that opens a port should be obvious when I look at the cluster file.
* *Roles define systems, clusters assemble systems into a machine*.
  - For example, a resque worker queue has a redis, a webserver and some config files -- your cluster should invoke a @whatever_queue@ role, and the @whatever_queue@ role should include recipes for the component services.
  - the existence of anything that opens a port _or_ runs as a service should be obvious when I look at the roles file.
* *include_recipe considered harmful* Do NOT use include_recipe for anything that a) provides a service, b) launches a daemon or c) is interesting in any way. (so: @include_recipe java@ yes; @include_recipe iptables@ no.) You should note the dependency in the metadata.rb. This seems weird, but the breaking behavior is purposeful: it makes you explicitly state all dependencies.
* It's nice when *machines are in full control of their destiny*. Their initial setup (elastic IP, attaching a drive) is often best enforced externally. However, machines should be able independently assert things like load balancer registration which may change at any point in their lifetime.
* It's even nicer, though, to have *full idempotency from the command line*: I can at any time push truth from the git repo to the chef server and know that it will take hold.

