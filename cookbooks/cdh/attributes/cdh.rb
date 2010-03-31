default[:hadoop][:hadoop_handle] = 'hadoop-0.20'
default[:hadoop][:cdh_version]   = 'cdh3'

default[:hadoop][:namenode_hostname]    = 'localhost'
default[:hadoop][:jobtracker_hostname]  = 'localhost'
default[:hadoop][:cluster_reduce_tasks] = 27

default[:hadoop][:dfs_replication] = 3

default[:groups]['hadoop'    ][:gid] = 300
default[:groups]['supergroup'][:gid] = 301

size        = 'm1.small'
ebs_volumes = []
using_ebs   = false

#
# Tune cluster settings for size of instance
#
case size
when 'm1.xlarge', 'c1.xlarge'
  hadoop_performance_settings = {
    :disks_to_prep        => [ ['/mnt2', '/dev/sdc'], ['/mnt3', '/dev/sdd'], ['/mnt4','/dev/sde'] ],
    :mapred_local_dirs    => '/mnt/hadoop/mapred/local,/mnt2/hadoop/mapred/local,/mnt3/hadoop/mapred/local,/mnt4/hadoop/mapred/local',
    :max_map_tasks        => 8,
    :max_reduce_tasks     => 4,
    :java_child_opts      => '-Xmx680m',
    :java_child_ulimit    => 1392640,
  }
when 'm1.large'
  hadoop_performance_settings = {
    :disks_to_prep        => [ ['/mnt2', '/dev/sdc'] ],
    :mapred_local_dirs    => '/mnt/hadoop/mapred/local,/mnt2/hadoop/mapred/local',
    :max_map_tasks        => 4,
    :max_reduce_tasks     => 2,
    :java_child_opts      => '-Xmx1024m',
    :java_child_ulimit    => 2097152,
  }
when 'm1.medium'
  hadoop_performance_settings = {
    :disks_to_prep        => [ ['/mnt2', '/dev/sdc'] ],
    :mapred_local_dirs    => '/mnt/hadoop/mapred/local',
    :max_map_tasks        => 4,
    :max_reduce_tasks     => 2,
    :java_child_opts      => '-Xmx550m',
    :java_child_ulimit    => 1126400,
  }
else # 'm1.small'
  hadoop_performance_settings = {
    :disks_to_prep        => [],
    :mapred_local_dirs    => '/mnt/hadoop/mapred/local',
    :max_map_tasks        => 2,
    :max_reduce_tasks     => 1,
    :java_child_opts      => '-Xmx550m',
    :java_child_ulimit    => 1126400,
  }
end
hadoop_performance_settings.each{|k,v| default[:hadoop][k] = v }

#
# If you're using EBS volumes, point the HDFS directorys thataways.
# Otherwise, make best use of the ephemeral drives
#
# TODO -- I think with EBS-backed we should change the below
#
case
when using_ebs
  hdfs_dirs = {
    :dfs_name_dirs         => ebs_volumes.map{|vol| "/#{vol}/hadoop/hdfs/name"     }.join(','),
    :fs_checkpoint_dirs    => ebs_volumes.map{|vol| "/#{vol}/hadoop/hdfs/secondary"}.join(','),
    :dfs_data_dirs         => ebs_volumes.map{|vol| "/#{vol}/hadoop/hdfs/data"     }.join(','),
  }
when ['m1.xlarge', 'c1.xlarge'].include?(size)
  hdfs_dirs = {
    :dfs_name_dirs         => '/mnt/hadoop/hdfs/name,/mnt2/hadoop/hdfs/name',
    :fs_checkpoint_dirs    => '/mnt/hadoop/hdfs/secondary,/mnt2/hadoop/hdfs/secondary',
    :dfs_data_dirs         => '/mnt/hadoop/hdfs/data,/mnt2/hadoop/hdfs/data,/mnt3/hadoop/hdfs/data,/mnt4/hadoop/hdfs/data',
  }
when ['m1.large'].include?(size)
  hdfs_dirs = {
    :dfs_name_dirs         => '/mnt/hadoop/hdfs/name,/mnt2/hadoop/hdfs/name',
    :fs_checkpoint_dirs    => '/mnt/hadoop/hdfs/secondary,/mnt2/hadoop/hdfs/secondary',
    :dfs_data_dirs         => '/mnt/hadoop/hdfs/data,/mnt2/hadoop/hdfs/data',
  }
else # 'm1.small', 'c1.medium'
  hdfs_dirs = {
    :dfs_name_dirs         => '/mnt/hadoop/hdfs/name',
    :fs_checkpoint_dirs    => '/mnt/hadoop/hdfs/secondary',
    :dfs_data_dirs         => '/mnt/hadoop/hdfs/data',
  }
end
hdfs_dirs.each{|k,v| default[:hadoop][k] = v }
