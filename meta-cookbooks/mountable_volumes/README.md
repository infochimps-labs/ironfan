# mountable_volumes chef cookbook

Mount volumes as directed by node metadata, and coordinate use of those volumes by other cookbooks.

## Overview

Cookbooks want to know not just what volumes are available, but their logical purpose: 'scratch space', 'persistent', 'super-fast flash-drive storage'. The details of that mapping shouldn't be their concern, only to request those resources and use them responsibly.

This meta-cookbook coordinates the machine's aspect of having various volumes and various systems cookbooks' concern of allocating storage on them.


Examples:

* Web server: in production, database lives on one volume, logs are written to another. On a cheaper test server, just
  put them whereever.

* Isolate different apps, each on their own volume

* Hadoop has the following mountable volume concerns:

  - Namenode metadata -- *must* be persistent. Physical clusters typically mirror to one NFS and two local volumes.
  - Datanode blocks   -- typically persistent. In a cloud environment, one strategy would be:
    - where available, permanent attachable drives (EBS volumes)
    - where available, local volumes (ephemeral drives)
    - as a last resort, whatever's present.
  - Scratch space for jobs -- should be fast, no need for it to be persistent.  On an EC2 instance, ephemeral drives
    would be preferred.

* Similarly, a Cassandra installation will place the commitlog the fastest available volume, the data store on the most
  persistent available volume. A Mongo or MySQL admin may allocate high-demand tables on an SSD, the rest on normal disks.

You ask for volume_dirs with
* a system
* a component (optional)
* a tag

We will look as follows:

* volumes tagged 'foo-
* volumes tagged 'foo-scratch'
* volumes tagged 'foo'
* volumes tagged 'scratch'

    System       	Component      	Type	Path           	Owner         	Mode 	Index 	attrs                          	Description
    ------       	---------      	----	----           	-----         	---- 	----- 	-----                          	-----------

topline
                                                                                                
    hadoop      	dfs_name       	perm	hdfs/name      	hdfs:hadoop  	0700	all	[:hadoop][:dfs_name_dirs]      	dfs.name.dir
    hadoop      	dfs_2nn        	perm	hdfs/secondary 	hdfs:hadoop  	0700	all	[:hadoop][:dfs_2nn_dirs ]      	dfs.name.dir
    hadoop      	dfs_data       	perm	hdfs/data      	hdfs:hadoop  	0755	all	[:hadoop][:dfs_data_dirs]      	dfs.data.dir
    hadoop      	mapred_local   	scratch	mapred/local   	mapred:hadoop	0775	all	[:hadoop][:mapred_local_dirs]  	mapred.local.dir
    hadoop      	log      	scratch	log      	hdfs:hadoop	0775	first	[:hadoop][:log_dir]      	mapred.local.dir
    hadoop      	tmp      	scratch	tmp      	hdfs:hadoop	0777	first	[:hadoop][:tmp_dir]      	mapred.local.dir

    hbase       	zk_data  	perm	zk/data  	hbase    	0755	first	[:hbase][:zk_data_dir]  	.
    hbase          	tmp      	scratch	tmp      	hbase    	0755	first	[:hbase][:tmp_dir]       	.

    zookeeper       	data     	perm	data     	zookeeper	0755	first	[:zookeeper][:data_dir]     	.
    zookeeper       	journal  	perm	journal  	zookeeper	0755	first	[:zookeeper][:journal_dir]  	.

    elasticsearch 	data    	perm	data      	elasticsearch  	0755	first	[:elasticsearch][:data_root]	.
    elasticsearch 	work    	scratch	work      	elasticsearch  	0755	first	[:elasticsearch][:work_root]  	.

    cassandra       	data    	perm	data     	cassandra   	0755	all	[:cassandra][:data_dirs]
    cassandra         	commitlog     	scratch	commitlog	cassandra   	0755	first	[:cassandra][:commitlog_dir]
    cassandra         	saved_caches   	scratch	saved_caches	cassandra   	0755	first	[:cassandra][:saved_caches_dir]

    flume       	conf    	.
    flume       	pid     	.
    flume        	data     	perm	data         	flume
    flume        	log      	scratch	data       	flume
    
    zabbix
    rundeck

    nginx
    mongodb

    scrapers      	data_dir
    api_stack    	.
    web_stack

hold

    redis       	data_dir
    redis          	work_dir
    redis        	log_dir
    
    statsd      	data_dir
    statsd      	log _dir

    graphite          	whisper  	perm
    graphite          	carbon   	perm
    graphite          	log_dir  	perm

    mysql
    sftp
    varnish
    ufw
    
kill

    tokyotyrant
    openldap
    nagios
    apache2
    rsyslog

### Memoized

Besides creating the directory, we store the calculated path into

  node[:system][:component][:handle]


## Attributes

* `[:mountable_volumes][:aws_credential_source]` -  (default: "data_bag")
* `[:mountable_volumes][:aws_credential_source]` -  (default: "data_bag")
* `[:mountable_volumes][:aws_credential_handle]` -  (default: "main")

## Recipes

* `default`                  - Base configuration for mountable_volumes
* `mount`                    - Mount

## Integration

Supports platforms: debian and ubuntu

Cookbook dependencies:
* aws


## License and Author

Author::                Philip (flip) Kromer - Infochimps, Inc (<coders@infochimps.com>)
Copyright::             2011, Philip (flip) Kromer - Infochimps, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

> readme generated by [cluster_chef](http://github.com/infochimps/cluster_chef)'s cookbook_munger
