module HadoopCluster
  # The namenode's hostname, or the local node's numeric ip if 'localhost' is given
  def namenode_address
    provider_private_ip("#{node[:cluster_name]}-namenode")
  end

  # The jobtracker's hostname, or the local node's numeric ip if 'localhost' is given
  def jobtracker_address
    provider_private_ip("#{node[:cluster_name]}-jobtracker")
  end

  def hadoop_package component
    package_name = (component ? "#{node[:hadoop][:hadoop_handle]}-#{component}" : "#{node[:hadoop][:hadoop_handle]}")
    package package_name do
      if node[:hadoop][:deb_version] != 'current'
        version node[:hadoop][:deb_version]
      end
    end
  end

  # Make a hadoop-owned directory
  def make_hadoop_dir dir, dir_owner, dir_mode="0755"
    directory dir do
      owner    dir_owner
      group    'hadoop'
      mode     dir_mode
      action   :create
      recursive true
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

  def hadoop_services
    %w[namenode secondarynamenode jobtracker datanode tasktracker].select do |svc|
      node[:provides_service]["#{node[:cluster_name]}-#{svc}"]
    end
  end

  # The HDFS data. Spread out across persistent storage only
  def dfs_data_dirs
    hadoop_persistent_dirs.map{|dir| File.join(dir, 'hdfs/data')}
  end

  # The HDFS metadata. Keep this on two different volumes, at least one persistent
  def dfs_name_dirs
    dirs = hadoop_persistent_dirs
    extra_nn_path = node[:hadoop][:extra_nn_metadata_path].to_s
    dirs << File.join(extra_nn_path, node[:cluster_name]) unless extra_nn_path.empty?
    dirs.map{|dir| File.join(dir, 'hdfs/name')}
  end

  # HDFS metadata checkpoint dir. Keep this on two different volumes, at least one persistent.
  def dfs_2nn_dirs
    dirs = hadoop_persistent_dirs
    extra_nn_path = node[:hadoop][:extra_nn_metadata_path].to_s
    dirs << File.join(extra_nn_path, node[:cluster_name]) unless extra_nn_path.empty?
    dirs.map{|dir| File.join(dir, 'hdfs/secondary')}
  end

  # Local storage during map-reduce jobs. Point at every local disk.
  def mapred_local_dirs
    hadoop_scratch_dirs.map{|dir| File.join(dir, 'mapred/local') }
  end

  # Temp storage
  def hadoop_tmp_dir
    hadoop_scratch_dirs.map{|dir| File.join(dir, 'tmp') }.first
  end

  # Hadoop logs
  def hadoop_log_dir
    hadoop_scratch_dirs.map{|dir| File.join(dir, 'logs') }.first
  end

  def hadoop_scratch_dirs
    [ node[:hadoop][:scratch_dirs],
      mounted_volumes_tagged(:hadoop_scratch).map{|vol_name, vol| vol[:mount_point]+"/hadoop" } ].flatten.uniq.compact
  end

  def hadoop_persistent_dirs
    [ node[:hadoop][:persistent_dirs],
      mounted_volumes_tagged(:hdfs).map{|vol_name, vol| vol[:mount_point]+"/hadoop" } ].flatten.uniq.compact
  end

  def hadoop_config_hash
    {
      :namenode_address       => provider_private_ip("#{node[:cluster_name]}-namenode"),
      :jobtracker_address     => provider_private_ip("#{node[:cluster_name]}-jobtracker"),
      #
      :dfs_name_dirs          => dfs_name_dirs.join(','),
      :dfs_data_dirs          => dfs_data_dirs.join(','),
      :dfs_2nn_dirs           => dfs_2nn_dirs.join(','),
      :mapred_local_dirs      => mapred_local_dirs.join(','),
      :hadoop_tmp_dir         => hadoop_tmp_dir,
      :hadoop_log_dir         => hadoop_log_dir,
      :hadoop_scratch_dirs    => hadoop_scratch_dirs,
      :hadoop_persistent_dirs => hadoop_persistent_dirs,
      #
      :aws                    => (node[:aws] && node[:aws].to_hash),
      #
      :ganglia                => provider_for_service("#{node[:cluster_name]}-gmetad"),
      :ganglia_address        => provider_private_ip("#{node[:cluster_name]}-gmetad"),
      :ganglia_port           => 8649,
    }
  end

end

class Chef::Recipe
  include HadoopCluster
end
class Chef::Resource::Directory
  include HadoopCluster
end
class Chef::Resource::Execute
  include HadoopCluster
end
class Chef::Resource::Template
  include HadoopCluster
end
