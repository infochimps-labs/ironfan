# volumes chef cookbook

Mounts volumes  as directed by node metadata. Can attach external cloud drives, such as ebs volumes.

## Overview

Write your recipes to request volumes

* **system-specific**: eg `mysql.data` or `nginx.log`.

* **persistent**: offer the best reliability.
* **local**:      low-latency bulk storage
* **fast**:       
* **bulk**:       largest pool of
* **reserved**:   

All of the above are positive rules: a volume is only `:fast` if it is labelled
`:fast`, and a volume is only `[:bulk, :persistent]` if it is 

The `fallback` tag has additional rules
* if any volumes are tagged `fallback`, return the full set of `fallback`s; otherwise,
* if any are *not* tagged `reserved`, return the full set of *non*-`reserved` volumes;
* raise an error if there are no un-reserved and no fallback 

### assigning labels

Labels are assigned by a human using (we hope) good taste -- there's no effort,
nor will there be, to presuppose that flash drives are `fast` or large drives
are `bulk`.  However, the cluster_chef provisioning tools do lend a couple
helpers: 

* `cloud(:ec2).defaults` describes a `:root`
  - tags it as `fallback`
  - if it is ebs, tags it 
  - does *not* marks it as `mountable`

* `cloud(:ec2).mount_ephemerals` knows (from the instance type) what ephemeral
  drives will be present. It:
  - populates volumes `ephemeral0` through (up to) `ephemeral3`
  - marks them as `mountable`
  - tags them as `local`, `bulk` and `fallback`
  - *removes* the `fallback` tag from the `:root` volume. (So be sure to call it *after*
    calling `defaults`.
    
You can explicitly override any of the above.


### examples


* Hadoop namenode metadata:
  - `:hadoop_namenode`
  - `:hadoop`
  - `[:persistent, :bulk]`
  - `:bulk`
  - `:fallback`


This meta-cookbook coordinates the machine's aspect of having various volumes and various systems cookbooks' concern of allocating storage on them.

Cookbooks want to know not just what volumes are available, but their logical purpose: 'scratch space', 'persistent', 'super-fast flash-drive storage'. The details of that mapping shouldn't be their concern, only to request those resources and use them responsibly.

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
                                                                                                
    hadoop      	dfs_name       	perm	hdfs/name      	hdfs:hadoop  	0700	all	[:hadoop][:namenode   ][:data_dirs]
    hadoop      	dfs_2nn        	perm	hdfs/secondary 	hdfs:hadoop  	0700	all	[:hadoop][:secondarynn][:data_dirs]    	dfs.name.dir
    hadoop      	dfs_data       	perm	hdfs/data      	hdfs:hadoop  	0755	all	[:hadoop][:datanode   ][:data_dirs]    	dfs.data.dir
    hadoop      	mapred_local   	scratch	mapred/local   	mapred:hadoop	0775	all	[:hadoop][:tasktracker][:scratch_dirs] 	mapred.local.dir
    hadoop      	log      	scratch	log      	hdfs:hadoop	0775	first	[:hadoop][:log_dir]                	mapred.local.dir
    hadoop      	tmp      	scratch	tmp      	hdfs:hadoop	0777	first	[:hadoop][:tmp_dir]              	mapred.local.dir

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

* `[:volumes][:volumes]`    - Logical description of volumes on this machine (default: "{}")
  - This hash maps an arbitrary name for a volume to its device path, mount point, filesystem type, and so forth.
  
  volumes understands the same arguments at the `mount` resource (nb. the prefix on `options`, `dump` and `pass`):
  
  * mount_point    (required to mount drive) The directory/path where the device should be mounted, eg '/data/redis'
  * device         (required to mount drive) The special block device or remote node, a label or an uuid to mount, eg '/dev/sdb'. See note below about Xen device name translation.
  * device_type    The type of the device specified -- :device, :label :uuid (default: `:device`)
  * fstype         The filesystem type (`xfs`, `ext3`, etc). If you omit the fstype, volumes will try to guess it from the device.
  * mount_options  Array or string containing mount options (default: `"defaults"`)
  * mount_dump     For entry in fstab file: dump frequency in days (default: `0`)
  * mount_pass     For entry in fstab file: Pass number for fsck (default: `2`)
  
  
  volumes offers special helpers if you supply these additional attributes:
  
  * :scratch       if true, included in `scratch_volumes` (default: `nil`)
  * :persistent    if true, included in `persistent_volumes` (default: `nil`)
  * :attachable    used by the `ec2::attach_volumes` cookbook.
  
  Here is an example, typical of an amazon m1.large machine:
  
    node[:volumes] = { :volumes => {
        :scratch1 => { :device => "/dev/sdb",  :mount_point => "/mnt", :scratch => true, },
        :scratch2 => { :device => "/dev/sdc",  :mount_point => "/mnt2", :scratch => true, },
        :hdfs1    => { :device => "/dev/sdj",  :mount_point => "/data/hdfs1", :persistent => true, :attachable => :ebs },
        :hdfs2    => { :device => "/dev/sdk",  :mount_point => "/data/hdfs2", :persistent => true, :attachable => :ebs },
      }
    }
  
  It describes two scratch drives (fast local storage, but wiped when the machine is torn down) and two persistent drives (network-attached virtual storage, permanently available).
  
  Note: On Xen virtualization systems (eg EC2), the volumes are *renamed* from /dev/sdj to /dev/xvdj -- but the amazon API requires you refer to it as /dev/sdj.
  
  If the `node[:virtualization][:system]` is 'xen' **and** there are no /dev/sdXX devices at all **and** there are /dev/xvdXX devices present, volumes will internally convert any device point of the form `/dev/sdXX` to `/dev/xvdXX`. If the example above is a Xen box, the values for :device will instead be `"/dev/xvdb"`, `"/dev/xvdc"`, `"/dev/xvdj"` and `"/dev/xvdk"`.
  
* `[:volumes][:aws_credential_source]` -  (default: "data_bag")
* `[:volumes][:aws_credential_handle]` -  (default: "main")

## Recipes 

* `build_raid`               - Build a raid array of volumes as directed by node[:volumes]
* `default`                  - Placeholder -- see other recipes in ec2 cookbook
* `mount`                    - Mount the volumes listed in node[:volumes]
## Integration

Supports platforms: debian and ubuntu

Cookbook dependencies:
* metachef


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
