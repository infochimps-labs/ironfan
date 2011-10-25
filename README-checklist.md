# Checklist for cookbooks, clusters and roles

## Clusters

* Describe physical configuration:
  - machine size, number of instances per facet, etc
  - external assets (elastic IP, ebs volumes)
* Describe high-level assembly of systems via roles: `hadoop_namenode`, `nfs_client`, `flume_client`, etc.
* Describe important modifications, such as `cluster_chef::system_internals`, mounts ebs volumes, etc
* Describe override attributes:
  - `heap size`, rvm versions, etc.

* roles and recipes 
  - remove `cluster_role` and `facet_role` if empty
  - are not in `run_list`, but populated by the `role` and `recipe` directives
* remove big_package unless it's a dev machine (sandbox, etc)

## Roles

Roles define the high-level assembly of recipes into systems

* 

* override attributes go into the cluster.
currently, those files are typically empty and are badly cluttering the roles/ directory.
the cluster and facet override attributes should be together, not scattered in different files.
roles shouldn't assemble systems. The contents of the infochimps_chef/roles/plato_truth.rb file belong in a facet.

* Deprecated: 
  - Cluster and facet roles (`roles/gibbon_cluster.rb`, `roles/gibbon_namenode.rb`, etc) go away
  - roles should be service-oriented: `hadoop_master` considered harmful, you should explicitly enumerate the services
  
  
## Cookbooks

* Dependencies are in metadata.rb, and include_recipe in the `default` recipe 
  - especially: `runit`, `java`, `cluster_service_discrovery`, `thrift`, `apt`
  - **include_recipe** is only used if putting it in the role would be utterly un-interesting. You *want* the run to break unless it's explicitly included the role. 
  - *yes*: `java`, `ruby`, `cluster_service_discovery`, etc.
  - *no*:  `zookeeper:client`, `nfs:server`, or anything that will start a daemon

* (*see TODO*) Does `cluster_service_discovery` uniformly handle referring to a foreign cluster for the service?

#### Recipes

* Naming:
  - foo/default    -- information shared by anyone using foo, including support packages, directories
  - foo/client     -- configure me as a foo client 
  - foo/server     -- configure me as a foo server
  - foo/aws_config -- cloud-specific settings
  
* Recipes shouldn't repeat their service name: `hbase:master` and not `hbase:hbase_master`; `zookeeper:server` not `zookeeper:zookeeper_server`.

#### Attributes

* Attribute file named ???? (which is the prefered name?)
 



