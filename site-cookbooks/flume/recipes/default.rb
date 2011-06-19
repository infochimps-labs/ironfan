#
# Cookbook Name:: flume
# Recipe:: default
#
# Copyright 2011, Infochimps, Inc.
#
# All rights reserved - Do Not Redistribute
#


#include_recipe "apt"


early = execute "add cloudera key" do
  command "curl -s http://archive.cloudera.com/debian/archive.key | sudo apt-k#ey add -"
  action :nothing
end

early.run_action(:run)

#apt_repository "cloudera" do
#  uri "http://archive.cloudera.com/debian"
#  distribution "maverick-cdh3" 
#  components ["contrib"]
#  action :add
#end

apt_repository "cloudera" do
  uri " http://archive.cloudera.com/debian"
  distribution "#{node['lsb']['codename']}-cdh3" # or "lucid" if lsb isn't installed :)
  components ["contrib"]
  key "http://archive.cloudera.com/debian/archive.key"
  action :add
end
 
package "flume"


class Chef::Resource::Template
 include FlumeCluster
end

template "/usr/lib/flume/conf/flume-site.xml" do
  source "flume-site.xml.erb"
  owner  "root"
  group  "flume"
  mode   "0644"
  variables({
              :masters            => flume_masters.join(","),
              :plugin_classes     => flume_plugin_classes,
              :classpath          => flume_classpath,
              :master_id          => flume_master_id,
              :external_zookeeper => flume_external_zookeeper,
              :zookeepers         => flume_zookeeper_list,
              :aws_access_key     => node[:flume][:aws_access_key],
              :aws_secret_key     => node[:flume][:aws_secret_key],
              :collector_output_format =>
                                     node[:flume][:collector][:output_format],
              :collector_codec     => node[:flume][:collector][:codec],
              :flume_data_dir      => node[:flume][:data_dir]
            })
end

template "/usr/lib/flume/bin/flume-env.sh" do
  source "flume-env.sh.erb"
  owner  "root"
  mode   "0744"
  variables({
              :classpath          => flume_classpath,
              :java_opts          => flume_java_opts,
            })
end

%w[commons-codec-1.4.jar commons-httpclient-3.0.1.jar 
   jets3t-0.6.1.jar].each do |file|
  cookbook_file "/usr/lib/flume/lib/#{file}" do
    owner "root"
    mode "644"
  end
end

directory "/usr/lib/flume/plugins" do
  owner "flume"
end

directory node[:flume][:data_dir] do
  owner "flume"
  recursive true
end
