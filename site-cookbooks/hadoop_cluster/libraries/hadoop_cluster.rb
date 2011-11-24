module HadoopCluster
  def hadoop_package component
    package_name = (component ? "#{node[:hadoop][:handle]}-#{component}" : "#{node[:hadoop][:handle]}")
    package package_name do
      if node[:hadoop][:deb_version] != 'current'
        version node[:hadoop][:deb_version]
      end
    end
  end

  def hadoop_services
    %w[namenode secondarynn jobtracker datanode tasktracker].select do |svc|
      node[:provides_service]["#{node[:cluster_name]}-#{svc}"]
    end
  end

  # {
  #   :namenode   => { ,  },
  #   :jobtracker => { :addr => provider_private_ip("#{node[:cluster_name]}-jobtracker") },
  #   :ganglia    => { :addr => provider_for_service("#{node[:cluster_name]}-gmetad"), :port => 8649, },
  #   #
  #   :dfs_name_dirs          => [:namenode         ][:data_dirs],
  #   :dfs_data_dirs          => node[:hadoop][:datanode         ][:data_dirs],
  #   :dfs_2nn_dirs           => node[:hadoop][:secondarynn][:data_dirs],
  #   :mapred_local_dirs      => node[:hadoop][:tasktracker      ][:work_dirs],
  #   :hadoop_tmp_dir         => node[:hadoop][:tmp_dir],
  #   :hadoop_log_dir         => node[:hadoop][:log_dir],
  #   # node[:hadoop][:imported][:classpaths]
  #   :extra_classpaths       => node[:hadoop][:extra_classpaths].map{|nm, classpath| classpath },
  #   #
  #   :aws                    => (node[:aws] && node[:aws].to_hash),
  # }
  def hadoop_config_hash
    Mash.new({
        :aws              => (node[:aws] && node[:aws].to_hash),
        :extra_classpaths => node[:hadoop][:extra_classpaths].map{|nm, classpath| classpath }.flatten,
      }).merge(node[:hadoop])
  end

  # # Make a hadoop-owned directory
  # def make_hadoop_dir dir, dir_owner, dir_mode="0755"
  #   directory dir do
  #     owner    dir_owner
  #     group    'hadoop'
  #     mode     dir_mode
  #     action   :create
  #     recursive true
  #   end
  # end
  #
  # # The HDFS data. Spread out across persistent storage only
  # def dfs_data_dirs
  #   hadoop_persistent_dirs.map{|dir| File.join(dir, 'hdfs/data')}
  # end
  #
  # # The HDFS metadata. Keep this on two different volumes, at least one persistent
  # def dfs_name_dirs
  #   dirs = hadoop_persistent_dirs
  #   extra_nn_path = node[:hadoop][:extra_nn_metadata_path].to_s
  #   dirs << File.join(extra_nn_path, node[:cluster_name]) unless extra_nn_path.empty?
  #   dirs.map{|dir| File.join(dir, 'hdfs/name')}
  # end
  #
  # # HDFS metadata checkpoint dir. Keep this on two different volumes, at least one persistent.
  # def dfs_2nn_dirs
  #   dirs = hadoop_persistent_dirs
  #   extra_nn_path = node[:hadoop][:extra_nn_metadata_path].to_s
  #   dirs << File.join(extra_nn_path, node[:cluster_name]) unless extra_nn_path.empty?
  #   dirs.map{|dir| File.join(dir, 'hdfs/secondary')}
  # end
  #
  # # Local storage during map-reduce jobs. Point at every local disk.
  # def mapred_local_dirs
  #   hadoop_scratch_dirs.map{|dir| File.join(dir, 'mapred/local') }
  # end
  #
  # # Temp storage
  # def hadoop_tmp_dir
  #   hadoop_scratch_dirs.map{|dir| File.join(dir, 'tmp') }.first
  # end
  #
  # # Hadoop logs
  # def hadoop_log_dir
  #   hadoop_scratch_dirs.map{|dir| File.join(dir, 'logs') }.first
  # end
  #
  # def hadoop_scratch_dirs
  #   [ node[:hadoop][:scratch_dirs],
  #     volumes_tagged(:hadoop_scratch).map{|vol_name, vol| vol[:mount_point]+"/hadoop" } ].flatten.uniq.compact
  # end
  #
  # def hadoop_persistent_dirs
  #   [ node[:hadoop][:persistent_dirs],
  #     volumes_tagged(:hdfs).map{|vol_name, vol| vol[:mount_point]+"/hadoop" } ].flatten.uniq.compact
  # end

  # Create a symlink to a directory, wiping away any existing dir that's in the way
  def force_link dest, src
    directory(dest) do
      action :delete ; recursive true
      not_if{ File.symlink?(dest) }
    end
    link(dest){ to src }
  end

end

class Chef::Recipe              ; include HadoopCluster ; end
class Chef::Resource::Directory ; include HadoopCluster ; end
class Chef::Resource::Execute   ; include HadoopCluster ; end
class Chef::Resource::Template  ; include HadoopCluster ; end
