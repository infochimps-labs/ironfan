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

