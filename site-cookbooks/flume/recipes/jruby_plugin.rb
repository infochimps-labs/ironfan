#
# Cookbook Name::       flume
# Description::         Jruby Plugin
# Recipe::              jruby_plugin
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

# Note: at the moment, you are on your own for installing jruby. You will have
# to set node[:flume][:classpath] to include the location for jruby to get this
# to work.

cookbook_file "/usr/lib/flume/plugins/jruby-flume.jar" do
  source "jruby-flume.jar"
  owner "flume"
  mode "0644"
end

directory "/usr/lib/flume/scripts" do
  owner "flume"
  mode "0755"
end

node[:flume][:plugins][:jruby_flume] ||= {}
node[:flume][:plugins][:jruby_flume][:classes]    = [ "com.infochimps.flume.jruby.JRubySink",
                                                      "com.infochimps.flume.jruby.JRubySource",
                                                      "com.infochimps.flume.jruby.JRubyDecorator", ]
node[:flume][:plugins][:jruby_flume][:classpath]  = [ "/usr/lib/flume/plugins/jruby-flume.jar","/usr/lib/jruby/lib/jruby.jar" ]
node[:flume][:plugins][:jruby_flume][:java_opts]  = [ "-Djruby.home=/usr/lib/jruby",
                                                      "-Djruby.lib=/usr/lib/jruby/lib",
                                                      "-Djruby.script=jruby", ]

node.save
