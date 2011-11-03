#!/usr/bin/env sh
#
# Cookbook Name:: hadoop_cluster
# Script Name::   bootstrap_hadoop_namenode
#
# Copyright 2011, Infochimps, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Make the standard HDFS directories:
#
#   /tmp
#   /user
#   /user/hive/warehouse
#
# and
#
#   /user/USERNAME
#
# for each user in the 'supergroup' group. Quoting Tom White:
#   "The [chmod +w] is questionable, as it allows a user to delete another
#    user. It's needed to allow users to create their own user directories"
#

set -e # die if any command fails                                                                                                                                                                                                                                               
# set -v # echo commands to the console                                                                                                                                                                                                                                         

# hadoop_tmp_dir="<%=    hadoop_tmp_dir %>"                                                                                                                                                                                                                                     
# dfs_name_dir_root="<%= File.join(dfs_name_dirs.first) %>"                                                                                                                                                                                                                     
# namenode_daemon="<%= "#{node[:hadoop][:hadoop_handle]}-namenode" %>"                                                                                                                                                                                                          

hadoop_tmp_dir=/mnt/hadoop/tmp
dfs_name_dir_root=/data/ebs1/hadoop/hdfs/name
namenode_daemon=hadoop-0.20-namenode

#                                                                                                                                                                                                                                                                               
# Format Namenode                                                                                                                                                                                                                                                               
#                                                                                                                                                                                                                                                                               
echo "Formatting namenode in '$dfs_name_dir_root'; daemon $namenode_daemon"

sudo service $namenode_daemon stop || sleep 3 ; true

if [ -f "$dfs_name_dir_root/current/VERSION" ] && [ -f "$dfs_name_dir_root/current/fsimage" ] ; then
  echo "Hadoop namenode appears to be formatted: exiting"
  exit
else
  echo "Executing namenode format!"
  sudo -u 'hdfs' hadoop namenode -format
fi

echo "Restarting the namenode"
sudo service $namenode_daemon start

echo "Waiting for the namenode to come out of safemode"
hadoop dfsadmin -safemode wait

echo "Preparing filesystem"

sentinel="$hadoop_tmp_dir/made_initial_dirs.log"
if [ -f "$sentinel" ] ; then
  echo "Looks like we already made the hdfs dirs -- try 'hadoop fs -lsr /' to see. if not, remove '$sentinel' and re-run."
else
  hadoop_users=/user/"`grep supergroup /etc/group | cut -d: -f4 | sed -e 's|,| /user/|g'`"
  hadoop_users="/user/ubuntu $hadoop_users"
  sudo -u hdfs hadoop fs -mkdir           /tmp /user /user/hive/warehouse $hadoop_users;
  sudo -u hdfs hadoop fs -chmod a+w       /tmp /user /user/hive/warehouse;
  sudo -u hdfs hadoop fs -mkdir           /hadoop/system/mapred
  sudo -u hdfs hadoop fs -chown -R mapred /hadoop/system
  sudo -u hdfs hadoop fs -chmod 700       /hadoop/system/mapred
  sudo -u hdfs hadoop fs -mkdir           /hadoop/hbase
  sudo -u hdfs hadoop fs -chown -R hbase  /hadoop/hbase
  for user in $hadoop_users ; do
    sudo -u hdfs hadoop fs -chown ${user#/user/} $user;
  done ;
  touch "$sentinel"
  true
fi

echo "Success! you can start the rest of the daemons now:"

echo 'for foo in datanode secondarynamenode tasktracker jobtracker ; do echo $foo ; sudo service hadoop-0.20-$foo start ; done'
