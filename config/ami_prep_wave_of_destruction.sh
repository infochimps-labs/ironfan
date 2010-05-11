#!/usr/bin/env bash

for foo in hadoop-0.20-{namenode,jobtracker,tasktracker,datanode,secondarynamenode} cassandra thttpd nfs-kernel-server \
    couchdb rabbitmq-server chef-{solr,solr-indexer,client,server,server-webui} ; do
  sudo service $foo stop ;
done

for foo in hadoop-0.20-{tasktracker,datanode,namenode,jobtracker,secondarynamenode} cassandra thttpd nfs-kernel-server ; do sudo update-rc.d -f $foo remove ; done

# ===========================================================================
#
# Manual Steps
#
#
# => Fix the /etc/hosts
cat /etc/hosts
#
# => Inspect the process list:
ps aux
#
# => Unmount anything that's mounted.
mount

history -c
away_dir=/mnt/tmp/away-`date "+%Y%m%d%H"`
sudo mkdir $away_dir
sudo mv /var/lib/couchdb/0.10.0/chef.couch /var/lib/rabbitmq/mnesia/rabbit /etc/hostname /etc/chef/{chef_config.json,*.pem,client.rb} $away_dir
sudo rm /var/lib/cloud/data/scripts/* /var/log/chef/* /etc/sv/*/log/main/* /var/log/*.gz /var/log/hadoop/* /tmp/* /var/log/rabbitmq/* /var/log/cassandra/* /var/run/hadoop*/* /var/www/* /var/lib/cloud/data/user-data.txt* /var/lib/cloud/data/*/*
sudo rm -rf /root/{.cache,.chef,emacs.d,.bash_history,.gem} ~ubuntu/{.cache,.chef,emacs.d,.bash_history,.gem}
sudo bash -c 'for foo in /var/log/{dmesg,syslog,messages,debug,udev,lastlog,faillog,dmesg.0,*.log} ; do echo -n > $foo ; done'
sudo mkdir -p $away_dir/ssh ; sudo mv /etc/ssh/ssh_*key* $away_dir/ssh

sudo rm -rf /data /var/backups/* 
sudo mv /var/chef /etc/hadoop/conf/*.xml /etc/hadoop/conf/*.chef-2* /etc/hadoop/conf/raw_settings.yaml* /etc/cassandra/storage-conf* $away_dir

# If you want to record the AMI version, something like
sudo rm /etc/motd ;
sudo bash -c 'echo "CHIMP CHIMP CHIMP CRUNCH CRUNCH CRUNCH (image burned at `date`)" > /etc/motd ' ;

for foo in /usr/lib/ruby/gems/1.8/gems/wukong-1.4.7/bin/* ; do sudo ln -s $foo /usr/local/bin/ ; done
