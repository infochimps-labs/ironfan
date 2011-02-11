#
# Cookbook Name:: flume
# Recipe:: jruby-flume
#
# Copyright 2011, Infochimps, Inc.
#
#

# Note: at the moment, you are on your own for installing jruby. You will have to set node[:flume][:classpath] to include the location for jruby to get this
# to work.

cookbookfile "/usr/lib/flume/plugins/jruby-flume.jar" do
  source "jruby-flume.jar"
end


node[:flume][:plugin][:jruby_flume][:classes]    ||=  %w[ com.infochimps.flume.jruby.JRubySink com.infochimps.flume.jruby.JRubySource com.infochimps.flume.JRubyDecorator ]
node[:flume][:plugin][:jruby_flume][:classpath]  ||=  %w[ /usr/lib/flume/plugins/jruby-flume.jar] 
