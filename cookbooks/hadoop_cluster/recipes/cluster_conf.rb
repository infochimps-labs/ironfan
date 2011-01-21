#
# Cookbook Name:: hadoop_cluster
# Recipe::        cluster_conf
#
class Chef::Recipe; include HadoopCluster ; end

#
# Configuration files
#
# Find these variables in ../hadoop_cluster/libraries/hadoop_cluster.rb
#
template_variables = {
  :namenode_address       => provider_private_ip("#{node[:cluster_name]}-namenode"),
  :jobtracker_address     => provider_private_ip("#{node[:cluster_name]}-jobtracker"),
  :mapred_local_dirs      => mapred_local_dirs.join(','),
  :dfs_name_dirs          => dfs_name_dirs.join(','),
  :dfs_data_dirs          => dfs_data_dirs.join(','),
  :fs_checkpoint_dirs     => fs_checkpoint_dirs.join(','),
  :local_hadoop_dirs      => local_hadoop_dirs,
  :persistent_hadoop_dirs => persistent_hadoop_dirs,
  :all_cluster_volumes    => all_cluster_volumes,
  :cluster_ebs_volumes    => cluster_ebs_volumes,
  :ganglia                => node[:hadoop][:ganglia],
  :ganglia_host           => provider_private_ip("#{node[:cluster_name]}-gmetad"),
  :ganglia_port           => 8649,
}
Chef::Log.debug template_variables.inspect
%w[raw_settings.yaml core-site.xml fairscheduler.xml hdfs-site.xml mapred-site.xml hadoop-metrics.properties].each do |conf_file|
  template "/etc/hadoop/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(template_variables)
    source "#{conf_file}.erb"
  end
end

template "/etc/default/#{node[:hadoop][:hadoop_handle]}" do
  owner "root"
  mode "0644"
  variables(template_variables)
  source "etc_default_hadoop.erb"
end

# Make hadoop logs live on /mnt/hadoop
hadoop_log_dir = '/mnt/hadoop/logs'
make_hadoop_dir(hadoop_log_dir, 'hdfs', "0775")
force_link("/var/log/hadoop", hadoop_log_dir )
force_link("/var/log/#{node[:hadoop][:hadoop_handle]}", hadoop_log_dir )

# Make hadoop point to /var/run for pids
make_hadoop_dir('/var/run/hadoop-0.20', 'root', "0775")
force_link('/var/run/hadoop', '/var/run/hadoop-0.20')
# Fix the hadoop-env.sh to point to /var/run for pids
hadoop_env_file = "/etc/#{node[:hadoop][:hadoop_handle]}/conf/hadoop-env.sh"
execute 'fix_hadoop_env-pid' do
  command %Q{sed -i -e 's|# export HADOOP_PID_DIR=.*|export HADOOP_PID_DIR=/var/run/hadoop|' #{hadoop_env_file}}
  not_if "grep 'HADOOP_PID_DIR=/var/run/hadoop' #{hadoop_env_file}"
end

# Set SSH options within the cluster
execute 'fix_hadoop_env-ssh' do
  command %Q{sed -i -e 's|# export HADOOP_SSH_OPTS=.*|export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no"| ' #{hadoop_env_file}}
  not_if "grep 'export HADOOP_SSH_OPTS=\"-o StrictHostKeyChecking=no\"' #{hadoop_env_file}"
end
