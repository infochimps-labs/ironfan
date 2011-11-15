# hadoop_cluster chef cookbook

Installs hadoop and sets up a high-performance cluster. Inspired by Tom White / Cloudera's hadoop-ec2 command line utilities

## Overview

= DESCRIPTION:

Installs Apache hadoop and sets up a basic distributed cluster per the quick start documentation.

= REQUIREMENTS:

== Platform:

Designed to work on the Amazon cloud using EBS-backed instances, though many parts of it will work elsewhere.

== Cookbooks:

Opscode cookbooks, http://github.com/opscode/cookbooks/tree/master:

* java

= ATTRIBUTES: 

* Hadoop package/version info:
** hadoop[:hadoop_handle] - Specify the package version of hadoop to install. Default hadoop-0.20
** hadoop[:cdh_version]   - Specify the cloudera distribution version. Default is cdh3 -- see http://archive.cloudera.com/docs/_apt.html
* You'll need to grab your AWS credentials from somewhere and stuff them in: 
** aws[:aws_access_key]
** aws[:aws_secret_access_key]
* See the corresponding entries in the hadoop documentation for the following:
** hadoop[:dfs_replication]           
** hadoop[:disks_to_prep].inspect     
** hadoop[:mapred_local_dirs]         
** hadoop[:max_map_tasks]             
** hadoop[:max_reduce_tasks]          
** hadoop[:cluster_reduce_tasks]      
** hadoop[:java_child_opts]           
** hadoop[:java_child_ulimit]         
** hadoop[:dfs_name_dirs]             
** hadoop[:fs_checkpoint_dirs]        
** hadoop[:dfs_data_dirs]             

You may wish to add more attributes for tuning the configuration file templates.

= DATABAGS:

You must construct a databag named "servers_info" containing the addresses
for the various central nodes. If your hadoop cluster is named 'zaius'
you'll set

  {"id":"zaius_namenode",  "private_ip":"10.212.171.245"}
  {"id":"zaius_jobtracker","private_ip":"10.212.171.245"}


= USAGE:

This cookbook installs hadoop from the cloudera CDH3 distribution[1] . You should copy this to a site-cookbook and modify the templates to meet your requirements. 

The various hadoop processes are installed as services. Do NOT use the start-all.sh scripts.  

The recipes correspond to different roles you'll probably assign: 
* pseudo-conf       -- single machine pseudo-distributed mode
* jobtracker        -- assigns and coordinates jobs
* namenode          -- runs the namenode (coordinates the HDFS) and secondarynamenode (backs up the metadata file)
* worker            -- runs the datanode and tasktracker
* secondarynamenode -- additional secondarynamenode (backs up the metadata file).

In the roles/ directory at http://github.com/mrflip/hadoop_cluster_chef there are defined chef roles for generic hadoop node, hadoop master (job, name, web, secondaryname services), and hadoop worker (data and task services)

Assign node roles according to these rough guidelines:

* For initial testing, use pseudo-conf mode.
* For clusters of some to a dozen or so nodes, give the master node the jobtracker, namenode *and* worker roles.
* For larger clusters, omit the worker role for the master node.
* For huge clusters, run the jobtracker and namenode/secondarynamenode on different hosts.

Note that the secondarynamenode is NOT a redundant namenode. All it does is make periodic backups of the HDFS metadata.

[1] http://archive.cloudera.com/docs/

= LICENSE and AUTHOR:
      
Author:: Joshua Timberman (<joshua@opscode.com>), Flip Kromer (<flip@infochimps.org>), much code taken from Tom White (<tom@cloudera.com>)'s hadoop-ec2 scripts and Robert Berger (http://blog.ibd.com)'s blog posts.

Copyright:: 2009, Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Attributes

* `[:cluster_size]`                   -  (default: "5")
* `[:hadoop][:hadoop_handle]`         -  (default: "hadoop-0.20")
* `[:hadoop][:cdh_version]`           -  (default: "cdh3u2")
* `[:hadoop][:deb_version]`           -  (default: "0.20.2+923.142-1~maverick-cdh3")
* `[:hadoop][:cloudera_distro_name]`  - 
* `[:hadoop][:dfs_replication]`       -  (default: "3")
* `[:hadoop][:reduce_parallel_copies]` -  (default: "10")
* `[:hadoop][:tasktracker_http_threads]` -  (default: "32")
* `[:hadoop][:jobtracker_handler_count]` -  (default: "40")
* `[:hadoop][:namenode_handler_count]` -  (default: "40")
* `[:hadoop][:datanode_handler_count]` -  (default: "8")
* `[:hadoop][:compress_output]`       -  (default: "true")
* `[:hadoop][:compress_output_type]`  -  (default: "BLOCK")
* `[:hadoop][:compress_output_codec]` -  (default: "org.apache.hadoop.io.compress.DefaultCodec")
* `[:hadoop][:compress_mapout]`       -  (default: "true")
* `[:hadoop][:compress_mapout_codec]` -  (default: "org.apache.hadoop.io.compress.DefaultCodec")
* `[:hadoop][:mapred_userlog_retain_hours]` -  (default: "24")
* `[:hadoop][:mapred_jobtracker_completeuserjobs_maximum]` -  (default: "100")
* `[:hadoop][:extra_classpaths]`      - 
* `[:hadoop][:daemon_heapsize]`       -  (default: "1000")
* `[:hadoop][:namenode_heapsize]`     - 
* `[:hadoop][:secondarynamenode_heapsize]` - 
* `[:hadoop][:jobtracker_heapsize]`   - 
* `[:hadoop][:persistent_dirs]`       - 
* `[:hadoop][:scratch_dirs]`          - 
* `[:hadoop][:max_balancer_bandwidth]` -  (default: "1048576")
* `[:hadoop][:min_split_size]`        -  (default: "134217728")
* `[:hadoop][:s3_block_size]`         -  (default: "134217728")
* `[:hadoop][:hdfs_block_size]`       -  (default: "134217728")
* `[:hadoop][:max_map_tasks]`         -  (default: "3")
* `[:hadoop][:max_reduce_tasks]`      -  (default: "2")
* `[:hadoop][:java_child_opts]`       -  (default: "-Xmx2432m -Xss128k -XX:+UseCompressedOops -XX:MaxNewSize=200m -server")
* `[:hadoop][:java_child_ulimit]`     -  (default: "7471104")
* `[:hadoop][:io_sort_factor]`        -  (default: "25")
* `[:hadoop][:io_sort_mb]`            -  (default: "256")
* `[:service_states][:hadoop_namenode]` - 
* `[:service_states][:hadoop_secondarynamenode]` - 
* `[:service_states][:hadoop_jobtracker]` - 
* `[:service_states][:hadoop_datanode]` - 
* `[:service_states][:hadoop_tasktracker]` - 
* `[:groups][:hadoop][:gid]`          -  (default: "300")
* `[:groups][:supergroup][:gid]`      -  (default: "301")
* `[:groups][:hdfs][:gid]`            -  (default: "302")
* `[:groups][:mapred][:gid]`          -  (default: "303")
* `[:server_tuning][:ulimit][:hdfs]`  - 
* `[:server_tuning][:ulimit][:hbase]` - 
* `[:server_tuning][:ulimit][:mapred]` - 

## Recipes 

* `cluster_conf`             - Cluster Conf
* `datanode`                 - Datanode
* `default`                  - Base configuration for hadoop_cluster
* `doc`                      - Doc
* `ec2_conf`                 - Ec2 Conf
* `hadoop_webfront`          - Hadoop Webfront
* `hdfs_fuse`                - Hdfs Fuse
* `jobtracker`               - Jobtracker
* `namenode`                 - Namenode
* `pseudo_distributed`       - Pseudo Distributed
* `secondarynamenode`        - Secondarynamenode
* `tasktracker`              - Tasktracker
* `update_apt`               - Update Apt
* `wait_on_hdfs_safemode`    - Wait On Hdfs Safemode


## Integration

Supports platforms: debian and ubuntu

Cookbook dependencies:
* java
* apt
* runit
* mountable_volumes
* provides_service


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
