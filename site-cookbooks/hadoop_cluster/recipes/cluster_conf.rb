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
Chef::Log.debug hadoop_config_hash.inspect
%w[raw_settings.yaml core-site.xml fairscheduler.xml hdfs-site.xml mapred-site.xml hadoop-metrics.properties].each do |conf_file|
  template "/etc/hadoop/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(hadoop_config_hash)
    source "#{conf_file}.erb"
  end
end

template "/etc/default/#{node[:hadoop][:hadoop_handle]}" do
  owner "root"
  mode "0644"
  variables(hadoop_config_hash)
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
