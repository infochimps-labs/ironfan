#
# Cookbook Name::       hadoop_cluster
# Description::         Cluster Conf
# Recipe::              cluster_conf
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef::Recipe; include HadoopCluster ; end

#
# Configuration files
#
# Find these variables in ../hadoop_cluster/libraries/hadoop_cluster.rb
#

%w[raw_settings.yaml core-site.xml fairscheduler.xml hdfs-site.xml mapred-site.xml hadoop-metrics.properties].each do |conf_file|
  template "/etc/hadoop/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(hadoop_config_hash)
    source "#{conf_file}.erb"
    hadoop_services.each do |svc|
      if node[:hadoop][svc][:service_state] && node[:hadoop][svc][:service_state].include?(:start)
        notifies :restart, "service[#{node[:hadoop][:handle]}-#{svc}]", :delayed
      end
    end
  end
end

template "/etc/default/#{node[:hadoop][:handle]}" do
  owner "root"
  mode "0644"
  variables(hadoop_config_hash)
  source "etc_default_hadoop.erb"
end

# Fix the hadoop-env.sh to point to /var/run for pids
hadoop_env_file = "/etc/#{node[:hadoop][:handle]}/conf/hadoop-env.sh"
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
#   munge_one_line("bump sleep time on #{daemon} runner", "/etc/init.d/#{node[:hadoop][:handle]}-#{daemon}",
#     %q{^SLEEP_TIME=.*}, %q{SLEEP_TIME=10 }, %q{^SLEEP_TIME=10 })
# end
