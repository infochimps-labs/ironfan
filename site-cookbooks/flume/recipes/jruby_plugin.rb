#
# Cookbook Name:: flume
# Recipe:: jruby-flume
#
# Copyright 2011, Infochimps, Inc.
#
#

# Note: at the moment, you are on your own for installing jruby. You will have to set node[:flume][:classpath] to include the location for jruby to get this
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
node[:flume][:plugins][:jruby_flume][:classpath]  = [ "/usr/lib/flume/plugins/jruby-flume.jar" ] 
node[:flume][:plugins][:jruby_flume][:java_opts]  = [ "-Djruby.home=/usr/lib/jruby",
                                                      "-Djruby.lib=/usr/lib/jruby/lib",
                                                      "-Djruby.script=jruby", ]

node.save
