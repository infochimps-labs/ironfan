module HadoopCluster

  # The namenode's hostname, or the local node's numeric ip if 'localhost' is given
  def namenode_hostname_or_ip
    if node[:hadoop][:namenode_hostname] == 'localhost'
      node[:cloud][:private_ips].first
    else
      node[:hadoop][:namenode_hostname]
    end
  end

  # The jobtracker's hostname, or the local node's numeric ip if 'localhost' is given
  def jobtracker_hostname_or_ip
    if node[:hadoop][:jobtracker_hostname] == 'localhost'
      node[:cloud][:private_ips].first
    else
      node[:hadoop][:jobtracker_hostname]
    end
  end

  # Make a hadoop-owned directory
  def make_hadoop_dir dir
    directory dir do
      owner    "hadoop"
      group    "hadoop"
      mode     "0755"
      action   :create
      recursive true
    end
  end

  def make_hadoop_dir_on_ebs dir
    directory dir do
      owner    "hadoop"
      group    "hadoop"
      mode     "0755"
      action   :create
      recursive true
      only_if{ cluster_ebs_volumes_are_mounted? }
    end
  end

  def ensure_hadoop_owns_hadoop_dirs dir
    execute "Make sure hadoop owns hadoop dirs" do

    end
  end

  # Create a symlink to a directory, wiping away any existing dir that's in the way
  def force_link dest, src
    directory(dest) do
      action :delete ; recursive true
      not_if{ File.symlink?(dest) }
    end
    link(dest){ to src }
  end

  def local_hadoop_dirs
    dirs = node[:hadoop][:local_disks].map{|mount_point, device| mount_point+'/hadoop' }
    dirs.unshift('/mnt/hadoop') if node[:hadoop][:use_root_as_scratch_vol]
    dirs.uniq
  end

  def persistent_hadoop_dirs
    if not cluster_ebs_volumes.blank?
      dirs = cluster_ebs_volumes.map{|vol_info| vol_info['mount_point']+'/hadoop' }
      dirs.unshift('/mnt/hadoop') if node[:hadoop][:use_root_as_persistent_vol]
      dirs.uniq
    else
      (['/mnt/hadoop'] + local_hadoop_dirs).uniq
    end
  end

  def cluster_ebs_volumes_are_mounted?
    return true if cluster_ebs_volumes.blank?
    cluster_ebs_volumes.all?{|vol_info| File.exists?(vol_info['device']) }
  end

  # The HDFS data. Spread out across persistent storage only
  def dfs_data_dirs
    persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/data') }
  end
  # The HDFS metadata. Keep this on two different volumes, at least one persistent
  def dfs_name_dirs
    persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/name') }
  end
  # HDFS metadata checkpoint dir. Keep this on two different volumes, at least one persistent.
  def fs_checkpoint_dirs
    persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/secondary') }
  end
  # Local storage during map-reduce jobs. Point at every local disk.
  def mapred_local_dirs
    local_hadoop_dirs.map{|dir| File.join(dir, 'mapred/local') }
  end

end

class Chef::Recipe
  include HadoopCluster
end
class Chef::Resource::Directory
  include HadoopCluster
end
