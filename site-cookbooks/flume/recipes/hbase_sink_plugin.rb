#
# Cookbook Name::       flume
# Description::         Hbase Sink Plugin
# Recipe::              hbase_sink_plugin
# Author::              Chris Howe - Infochimps, Inc
#
# Copyright 2011, Infochimps, Inc.
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

include_recipe 'metachef'

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

node_changed!
