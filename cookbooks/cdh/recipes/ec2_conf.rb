#
# Cookbook Name:: hadoop
# Recipe:: ec2_conf
#
# Copyright 2010, Infochimps, Inc.
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
# Configuration files
#
%w[core-site.xml fairscheduler.xml hdfs-site.xml mapred-site.xml hadoop-metrics.properties].each do |conf_file|
  template "/etc/hadoop/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    source "#{conf_file}.erb"
  end
end

#
# Mount big ephemeral drives
#
mount '/mnt' do
  device '/dev/sdc'
  fstype 'ext3'
end
# package 'xfsprogs'

# TODO -- libraries?
def make_hadoop_dir dir
  directory dir do
    owner    "hadoop"
    group    "hadoop"
    mode     "0755"
    action   :create
    recursive true
  end
end
def force_link dest, src
  directory(dest) do
    action :delete ; recursive true
    not_if{ File.symlink?(dest) }
  end
  link(dest){ to src }
end

#
# HDFS directories
#

node[:hadoop][:disks_to_prep     ].each{ |mnt| make_hadoop_dir "#{mnt}/hadoop" }
node[:hadoop][:dfs_name_dirs     ].split(',').each{|dir| make_hadoop_dir(dir) }
node[:hadoop][:dfs_data_dirs     ].split(',').each{|dir| make_hadoop_dir(dir) }
node[:hadoop][:mapred_local_dirs ].split(',').each{|dir| make_hadoop_dir(dir) }
node[:hadoop][:fs_checkpoint_dirs].split(',').each{|dir| make_hadoop_dir(dir) }
directory '/mnt/tmp' do
  owner     'hadoop'
  group     'hadoop'
  mode      '0777'
  action    :create
  recursive true
end
hadoop_log_dir = '/mnt/hadoop/logs'
make_hadoop_dir(hadoop_log_dir)
force_link("/var/log/hadoop", hadoop_log_dir )
force_link("/var/log/#{node[:hadoop][:hadoop_handle]}", hadoop_log_dir )

#
# Fix the hadoop-env.sh
#
hadoop_env_file = "/etc/#{node[:hadoop][:hadoop_handle]}/conf/hadoop-env.sh"
# Keep PID files in a non-temporary directory
make_hadoop_dir('/var/run/hadoop-0.20')
force_link('/var/run/hadoop', '/var/run/hadoop-0.20')
execute 'fix_hadoop_env-pid' do
  command %Q{sed -i -e "s|# export HADOOP_PID_DIR=.*|export HADOOP_PID_DIR=/var/run/hadoop|" #{hadoop_env_file}}
  not_if %Q{grep "HADOOP_PID_DIR=/var/run/hadoop" #{hadoop_env_file}}
end
# Set SSH options within the cluster
execute 'fix_hadoop_env-ssh' do
  command %Q{sed -i -e 's|# export HADOOP_SSH_OPTS=.*|export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no"|' #{hadoop_env_file}}
  not_if %Q{grep 'export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no"' #{hadoop_env_file}}
end

#
# Format Namenode
#
execute 'format_namenode' do
  command %Q{yes 'Y' | hadoop namenode -format}
  user 'hadoop'
  creates '/mnt/hadoop/hdfs/name/current/VERSION'
  creates '/mnt/hadoop/hdfs/name/current/fsimage'
end

# TODO: wait for mount
# function wait_for_mount {
#   mount=$1
#   device=$2
#
#   mkdir $mount
#
#   i=1
#   echo "Attempting to mount $device"
#   while true ; do
#     sleep 10
#     echo -n "$i "
#     i=$[$i+1]
#     mount -o defaults,noatime $device $mount || continue
#     echo " Mounted."
#     if $automount ; then
#       echo "$device $mount xfs defaults,noatime 0 0" >> /etc/fstab
#     fi
#     break;
#   done
# }
#
# TODO: modify /etc/fstab
# TODO:
# function prep_disk() {
#   mount=$1
#   device=$2
#   automount=${3:-false}
#
#   echo "warning: ERASING CONTENTS OF $device"
#   mkfs.xfs -f $device
#   if [ ! -e $mount ]; then
#     mkdir $mount
#   fi
#   mount -o defaults,noatime $device $mount
#   if $automount ; then
#     echo "$device $mount xfs defaults,noatime 0 0" >> /etc/fstab
#   fi
# }

#
# Do work /on/ the HDFS
#

#
# $AS_HADOOP "$HADOOP dfsadmin -safemode wait"
#
#
# TODO -- Make the user dirs on the hdfs
#   $HADOOP_COMMAND fs -mkdir /user
#   # The following is questionable, as it allows a user to delete another user
#   # It's needed to allow users to create their own user directories
#   $AS_HADOOP "/usr/bin/$HADOOP fs -chmod +w /user"
#   # for each user, make their directory and chown it to them
#
#   # Create temporary directory for Pig and Hive in HDFS
#   $AS_HADOOP "/usr/bin/$HADOOP fs -mkdir /tmp"
#   $AS_HADOOP "/usr/bin/$HADOOP fs -chmod +w /tmp"
#   $AS_HADOOP "/usr/bin/$HADOOP fs -mkdir /user/hive/warehouse"
#   $AS_HADOOP "/usr/bin/$HADOOP fs -chmod +w /user/hive/warehouse"

