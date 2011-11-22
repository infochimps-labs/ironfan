## Tips and Notes

### EC2 Notes Instance attributes: `disable_api_termination` and `delete_on_termination`

To set `delete_on_termination` to 'true' after the fact, run the following (modify the instance and volume to suit):

```
  ec2-modify-instance-attribute -v i-0704be6c --block-device-mapping /dev/sda1=vol-XX8d2c80::true
```
  
If you set `disable_api_termination` to true, in order to terminate the node run
```
  ec2-modify-instance-attribute -v i-0704be6c --disable-api-termination false
```

### EC2: See your userdata

curl http://169.254.169.254/latest/user-data


### EBS Volumes for a persistent HDFS

* Make one volume and format for XFS:
    `$ sudo mkfs.xfs -f /dev/sdh1`
* options "defaults,nouuid,noatime" give good results. The 'nouuid' part
  prevents errors when mounting multiple volumes from the same snapshot.
* poke a file onto the drive :
  datename=`date +%Y%m%d`
  sudo bash -c "(echo $datename ; df /data/ebs1 ) > /data/ebs1/xfs-created-at-$datename.txt"


If you want to grow the drive: 
* take a snapshot.
* make a new volume from it
* mount that, and run `sudo xfs_growfs`

### Hadoop: On-the-fly backup of your namenode metadata

bkupdir=/ebs2/hadoop-nn-backup/`date +"%Y%m%d"`

for srcdir in /ebs*/hadoop/hdfs/ /home/hadoop/gibbon/hdfs/  ; do
  destdir=$bkupdir/$srcdir ; echo $destdir ;
  sudo mkdir -p $destdir ;
done


### Hadoop: namenode bootstrap

Once the master runs to completion with all daemons started, remove the hadoop_initial_bootstrap recipe from its run_list. (Note that you may have to edit the runlist on the machine itself depending on how you bootstrapped the node).

### NFS: Halp I am using an NFS-mounted /home and now I can't log in as ubuntu

Say you set up an NFS server 'core-homebase-0' (in the 'core' cluster) to host and serve out `/home` directory; and a machine 'awesome-webserver-0' (in the 'awesome' cluster), that is an NFS client.

In each case, when the machine was born EC2 created a `/home/ubuntu/.ssh/authorized_keys` file listing only the single approved machine keypair -- 'core' for the core cluster, 'awesome' for the awesome cluster.

When chef client runs, however, it mounts the NFS share at /home. This then masks the actual /home directory -- nothing that's on the base directory tree shows up. Which means that after chef runs, the /home/ubuntu/.ssh/authorized_keys file on awesome-webserver-0 is the one for the *'core'* cluster, not the *'awesome'* cluster.

The solution is to use the cookbook cluster_chef provides -- it moves the 'ubuntu' user's home directory to an alternative path not masked by the NFS.


### NFS: Problems starting NFS server on ubuntu maverick 

For problems starting NFS server on ubuntu maverick systems, read, understand and then run /tmp/fix_nfs_on_maverick_amis.sh -- See "this thread for more":http://fossplanet.com/f10/[ec2ubuntu]-not-starting-nfs-kernel-daemon-no-support-current-kernel-90948/


### Git deploys: My git deploy recipe has gone limp

Suppose you are using the @git@ resource to deploy a recipe (@george@ for sake of example). If @/var/chef/cache/revision_deploys/var/www/george@ exists then *nothing* will get deployed, even if /var/www/george/{release_sha} is empty or screwy.  If git deploy is acting up in any way, nuke that cache from orbit -- it's the only way to be sure.

 $ sudo rm -rf /var/www/george/{release_sha} /var/chef/cache/revision_deploys/var/www/george

### Runit services : 'fail: XXX: unable to change to service directory: file does not exist'

Your service is probably installed but removed from runit's purview; check the `/etc/service` symlink. All of the following should be true: 

* directory `/etc/sv/foo`, containing file `run` and dirs `log` and `supervise`
* `/etc/init.d/foo`  is symlinked to `/usr/bin/sv`
* `/etc/servics/foo` is symlinked tp `/etc/sv/foo`


### Nuke it from orbit, it's the only way to be sure

These are likely to clobber way more than their base services.

    sudo service cassandra      stop ; 
    sudo service redis_server   stop ; 
    sudo service ganglia_server stop ; sudo service ganglia_monitor stop 
    for foo in hadoop-0.20-{namenode,secondarynamenode,jobtracker,tasktracker,datanode} ; do sudo service $foo stop ; done
    for foo in hadoop-{zookeeper-server,hbase-master,hbase-regionserver} ; do sudo service $foo stop ; done
    for foo in statsd graphite_web graphite_whisper graphite_carbon resque_dashboard ; do sudo service $foo stop ; done
    sudo killall nginx
    
    sudo apt-get -y remove --purge redis-server
    sudo apt-get -y remove --purge hadoop-0.20 hadoop-0.20-{namenode,secondarynamenode,jobtracker,tasktracker,datanode,doc,native}
    sudo apt-get -y remove --purge hadoop-zookeeper-server hadoop-pig 
    sudo apt-get -y remove --purge gmetad ganglia-monitor 
    
    svc=cassandra    ; sudo rm -f /etc/service/$svc          ; sudo rm -rf /var/*/$svc /etc/$svc     /etc/sv/${svc}*  /etc/init.d/${svc}* /usr/local/{share,src}/${svc}* ; sudo userdel $svc ; sudo groupdel $svc 
    svc=redis        ; sudo rm -f /etc/service/${svc}_server ; sudo rm -rf /var/*/$svc /etc/$svc     /etc/sv/${svc}_* /etc/init.d/${svc}* /usr/local/{share,src}/${svc}* ; sudo userdel $svc ; sudo groupdel $svc ; 
    svc=ganglia      ; sudo rm -f /etc/service/${svc}_*      ; sudo rm -rf /var/*/$svc /etc/$svc     /etc/sv/${svc}_* /etc/init.d/${svc}* ; sudo userdel $svc ; sudo groupdel $svc ; 
    svc=hadoop       ; sudo rm -f /etc/service/${svc}*       ; sudo rm -rf /var/*/$svc /etc/${svc}*  /etc/sv/${svc}*  /etc/init.d/${svc}* ; sudo userdel hdfs ; sudo userdel mapred ; sudo groupdel hdfs ; sudo groupdel mapred ; sudo groupdel hadoop ; 

    svc=elasticsearch; sudo rm -f /etc/service/${svc}        ; sudo rm -rf /var/*/$svc /etc/$svc     /etc/sv/${svc}   /etc/init.d/${svc}* /usr/local/{share,src}/${svc}* ; sudo userdel $svc ; sudo groupdel $svc

    svc=statsd       ; sudo rm -f /etc/service/${svc}        ; sudo rm -rf /var/*/$svc /etc/$svc     /etc/sv/${svc}   /etc/init.d/${svc}* /usr/local/{share,src}/${svc}* ; sudo userdel $svc ; sudo groupdel $svc 
    svc=resque       ; sudo rm -f /etc/service/${svc}_*      ; sudo rm -rf /var/*/$svc /etc/$svc     /etc/sv/${svc}_* /etc/init.d/${svc}* /usr/local/{share,src}/${svc}* ; sudo userdel $svc ; sudo groupdel $svc 

    svc=jruby         ; sudo rm -rf /etc/$svc /usr/local/{share,src}/${svc}* 
