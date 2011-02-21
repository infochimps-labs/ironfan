#
# Cookbook Name:: hadoop_cluster
# Recipe::        ec2_conf
#

#
# Mount big ephemeral drives, make hadoop dirs on them
#
node[:hadoop][:local_disks].each do |mount_point, dev|
  Chef::Log.info ['mounting local', mount_point, dev]
  directory mount_point do
    owner     'root'
    group     'root'
    mode      '0755'
    action    :create
  end

  dev_fstype = fstype_from_file_magic(dev)
  mount mount_point do
    only_if{ dev && dev_fstype }
    only_if{ File.exists?(dev) }
    device dev
    fstype dev_fstype
  end
end
local_hadoop_dirs.each do |dir|
  make_hadoop_dir dir, 'hdfs'
end

# Temp dir
directory '/mnt/tmp' do
  owner     'hdfs'
  group     'hadoop'
  mode      '0777'
  action    :create
end

#
# Make hadoop dirs on persistent drives
#
if cluster_ebs_volumes
  cluster_ebs_volumes.each do |vol_info|
    Chef::Log.info ["HDFS data dir", vol_info].inspect
    make_hadoop_dir_on_ebs( vol_info['mount_point']+'/hadoop', 'hdfs' )
  end
end

# Important: In CDH3 Beta 3, the mapred.system.dir directory must be located inside a directory that is owned by mapred. For example, if mapred.system.dir is specified as /mapred/system, then /mapred must be owned by mapred. Don't, for example, specify /mrsystem as mapred.system.dir because you don't want / owned by mapred.
#
# Directory             Owner           Permissions
# dfs.name.dir          hdfs:hadoop     drwx------
# dfs.data.dir          hdfs:hadoop     drwxr-xr-x
# mapred.local.dir      mapred:hadoop   drwxr-xr-x
# mapred.system.dir     mapred:hadoop   drwxr-xr-x

#
# Physical directories for HDFS files and metadata
#
dfs_name_dirs.each{      |dir| make_hadoop_dir_on_ebs(dir, 'hdfs',   "0700") }
dfs_data_dirs.each{      |dir| make_hadoop_dir_on_ebs(dir, 'hdfs',   "0755") }
fs_checkpoint_dirs.each{ |dir| make_hadoop_dir_on_ebs(dir, 'hdfs',   "0700") }
mapred_local_dirs.each{  |dir| make_hadoop_dir_on_ebs(dir, 'mapred', "0755") }

