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

Chef::Log.info([ node[:cluster_name], node[:facet_name], hadoop_services, hadoop_config_hash ].inspect)

%w[raw_settings.yaml core-site.xml fairscheduler.xml hdfs-site.xml mapred-site.xml hadoop-metrics.properties].each do |conf_file|
  template "/etc/hadoop/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(hadoop_config_hash)
    source "#{conf_file}.erb"
    hadoop_services.each do |svc|
      if node[:service_states][svc] && node[:service_states][svc].include?(:start)
        notifies :restart, "service[#{node[:hadoop][:hadoop_handle]}-#{svc}]", :delayed
      end
    end
  end
end

template "/etc/default/#{node[:hadoop][:hadoop_handle]}" do
  owner "root"
  mode "0644"
  variables(hadoop_config_hash)
  source "etc_default_hadoop.erb"
end

# Fix the hadoop-env.sh to point to /var/run for pids
hadoop_env_file = "/etc/#{node[:hadoop][:hadoop_handle]}/conf/hadoop-env.sh"
execute 'fix_hadoop_env-pid' do
  command %Q{sed -i -e 's|# export HADOOP_PID_DIR=.*|export HADOOP_PID_DIR=/var/run/hadoop|' #{hadoop_env_file}}
  not_if "grep 'HADOOP_PID_DIR=/var/run/hadoop' #{hadoop_env_file}"
end

# Set SSH options within the cluster
munge_one_line('fix hadoop ssh options', hadoop_env_file,
  %q{\# export HADOOP_SSH_OPTS=.*},
  %q{export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no"},
  %q{export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no"}
  )

# $HADOOP_NODENAME is set in /etc/default/hadoop

munge_one_line('use node name in hadoop .log logs', '/usr/lib/hadoop/bin/hadoop-daemon.sh',
  %q{export HADOOP_LOGFILE=hadoop-.HADOOP_IDENT_STRING-.command-.HOSTNAME.log},
  %q{export HADOOP_LOGFILE=hadoop-$HADOOP_IDENT_STRING-$command-$HADOOP_NODENAME.log},
  %q{^export HADOOP_LOGFILE.*HADOOP_NODENAME}
  )

munge_one_line('use node name in hadoop .out logs', '/usr/lib/hadoop/bin/hadoop-daemon.sh',
  %q{export _HADOOP_DAEMON_OUT=.HADOOP_LOG_DIR/hadoop-.HADOOP_IDENT_STRING-.command-.HOSTNAME.out},
  %q{export _HADOOP_DAEMON_OUT=$HADOOP_LOG_DIR/hadoop-$HADOOP_IDENT_STRING-$command-$HADOOP_NODENAME.out},
  %q{^export _HADOOP_DAEMON_OUT.*HADOOP_NODENAME}
  )

# %w[namenode secondarynamenode jobtracker datanode tasktracker].each do |daemon|
#   munge_one_line("bump sleep time on #{daemon} runner", "/etc/init.d/#{node[:hadoop][:hadoop_handle]}-#{daemon}",
#     %q{^SLEEP_TIME=.*}, %q{SLEEP_TIME=10 }, %q{^SLEEP_TIME=10 })
# end
