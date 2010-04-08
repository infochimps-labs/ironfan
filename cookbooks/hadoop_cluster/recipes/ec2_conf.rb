#
# Cookbook Name:: hadoop_cluster
# Recipe::        ec2_conf
#
class Chef::Recipe; include HadoopCluster ; end

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
    dev_fstype = nil
    begin
      dev_type_str = `file -s '#{dev}'`
      Chef::Log.info [dev_type_str].inspect
      case
      when dev_type_str =~ /SGI XFS filesystem data/     then dev_fstype = 'xfs'
      when dev_type_str =~ /Linux.*ext3 filesystem data/ then dev_fstype = 'ext3'
      else dev_fstype = nil
      end
      Chef::Log.info [dev_fstype].inspect
    rescue Exception => e
      warn [e.message, e.backtrace].flatten.join("\n")
    end
    only_if{ dev && dev_fstype }
    device dev
    fstype dev_fstype
  end
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
if cluster_ebs_volumes
  cluster_ebs_volumes.each do |vol_info|
    Chef::Log.info vol_info.inspect
    make_hadoop_dir_on_ebs( vol_info['mount_point']+'/hadoop' )
  end
end

#
# Physical directories for HDFS files and metadata
#
dfs_name_dirs.each{      |dir| make_hadoop_dir_on_ebs(dir); ensure_hadoop_owns_hadoop_dirs(dir) }
dfs_data_dirs.each{      |dir| make_hadoop_dir_on_ebs(dir); ensure_hadoop_owns_hadoop_dirs(dir) }
fs_checkpoint_dirs.each{ |dir| make_hadoop_dir_on_ebs(dir); ensure_hadoop_owns_hadoop_dirs(dir) }
mapred_local_dirs.each{  |dir| make_hadoop_dir_on_ebs(dir); ensure_hadoop_owns_hadoop_dirs(dir) }

