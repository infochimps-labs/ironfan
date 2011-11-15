
This cookbook installs zookeeper from the Cloudera apt repo.

The server recipe additionally
* creates the service, and applies the state given in `node[:zookeeper][:server][:daemon_state]`
* announces that it `provides_service` "{cluster_name}-zookeeper"
