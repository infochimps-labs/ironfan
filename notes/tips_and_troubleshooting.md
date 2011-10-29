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

### Hadoop: On-the-fly backup of your namenode metadata

bkupdir=/ebs2/hadoop-nn-backup/`date +"%Y%m%d"`

for srcdir in /ebs*/hadoop/hdfs/ /home/hadoop/gibbon/hdfs/  ; do
  destdir=$bkupdir/$srcdir ; echo $destdir ;
  sudo mkdir -p $destdir ;
done


### Halp I am using an NFS-mounted /home and now I can't log in as ubuntu

Say you set up an NFS server 'core-homebase-0' (in the 'core' cluster) to host and serve out `/home` directory; and a machine 'awesome-webserver-0' (in the 'awesome' cluster), that is an NFS client.

In each case, when the machine was born EC2 created a `/home/ubuntu/.ssh/authorized_keys` file listing only the single approved machine keypair -- 'core' for the core cluster, 'awesome' for the awesome cluster.

When chef client runs, however, it mounts the NFS share at /home. This then masks the actual /home directory -- nothing that's on the base directory tree shows up. Which means that after chef runs, the /home/ubuntu/.ssh/authorized_keys file on awesome-webserver-0 is the one for the *'core'* cluster, not the *'awesome'* cluster.

The solution is to use the cookbook cluster_chef provides -- it moves the 'ubuntu' user's home directory to an alternative path not masked by the NFS.