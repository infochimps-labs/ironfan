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
