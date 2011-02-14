#
# Cookbook Name:: flume
# Recipe:: default
#
# Copyright 2011, Infochimps, Inc.
#
# All rights reserved - Do Not Redistribute
#

package "flume"


class Chef::Resource::Template
 include FlumeCluster
end

template "/etc/flume/conf/flume-site.xml" do
  source "flume-site.xml.erb"
  owner  "root"
  mode   "0644"
  variables({
              :masters            => flume_masters.join(","),
              :plugin_classes     => flume_plugin_classes,
              :classpath          => flume_classpath,
              :master_id          => flume_master_id,
              :external_zookeeper => flume_external_zookeeper,
              :zookeepers         => flume_zookeeper_list,
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


directory "/usr/lib/flume/plugins" do
  owner "flume"
end
