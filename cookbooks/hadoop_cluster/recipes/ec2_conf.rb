#
# Cookbook Name:: hadoop_cluster
# Recipe::        ec2_conf
#
class Chef::Recipe; include HadoopCluster ; end

p node[:hadoop].to_hash

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
  # execute
  mount mount_point do
    fstype 'xfs'
    device dev
  end if dev
end
local_hadoop_dirs.each do |dir|
  make_hadoop_dir dir
end

# Temp dir
directory '/mnt/tmp' do
  owner     'hadoop'
  group     'hadoop'
  mode      '0777'
  action    :create
end

#
# Make hadoop dirs on persistent drives
#
cluster_ebs_volumes.each do |vol_info|
  Chef::Log.info vol_info.inspect
  make_hadoop_dir_on_ebs( vol_info['mount_point']+'/hadoop' )
end

#
# Physical directories for HDFS files and metadata
#
dfs_name_dirs.each{      |dir| make_hadoop_dir_on_ebs(dir) }
dfs_data_dirs.each{      |dir| make_hadoop_dir_on_ebs(dir) }
fs_checkpoint_dirs.each{ |dir| make_hadoop_dir_on_ebs(dir) }
mapred_local_dirs.each{  |dir| make_hadoop_dir_on_ebs(dir) }

