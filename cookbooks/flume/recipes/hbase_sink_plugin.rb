#
# Cookbook Name:: flume
# Recipe:: hbase_sink_plugin
#
# Copyright 2011, Infochimps, Inc.
#
#


cookbook_file "/usr/lib/flume/plugins/hbase-sink.jar" do
  source "hbase-sink.jar"
  owner "flume"
  mode "0644"
end

# Load Attr2HbaseEventSink as a plugin
node[:flume][:plugins][:hbase_sink]  ||= {}
node[:flume][:plugins][:hbase_sink][:classes] =  [ "com.cloudera.flume.hbase.Attr2HBaseEventSink" ]

# Make sure that hbase-sink.jar and hbase-site.xml can be located on the
# classpath
node[:flume][:plugins][:hbase_sink][:classpath]  =  [ "/usr/lib/flume/plugins/hbase-sink.jar", "/etc/hbase/conf" ] 

node[:flume][:plugins][:hbase_sink][:java_opts] =  []

node.save
