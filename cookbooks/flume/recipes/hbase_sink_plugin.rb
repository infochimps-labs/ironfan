#
# Cookbook Name:: flume
# Recipe:: hbase_sink_plugin
#
# Copyright 2011, Infochimps, Inc.
#
#


cookbookfile "/usr/lib/flume/plugins/hbase-sink.jar" do
  source "hbase-sink.jar"
end

# Load Attr2HbaseEventSink as a plugin
node[:flume][:plugin][:hbase_sink][:classes]    ||=  %w[ com.cloudera.flume.hbase.Attr2HBaseEventSink ]

# Make sure that hbase-sink.jar and hbase-site.xml can be located on the
# classpath
node[:flume][:plugin][:hbase_sink][:classpath]  ||=  %w[ /usr/lib/flume/plugins/hbase-sink.jar /usr/hbase/conf ] 
