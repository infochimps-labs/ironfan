# Checklist for cookbooks, clusters and roles

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
 

## Cluster 

* roles and recipes 
  - remove `cluster_role` and `facet_role` if empty
  - are not in `run_list`, but populated by the `role` and `recipe` directives
* 



