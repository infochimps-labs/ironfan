#
# Cookbook Name:: flume
# Recipe:: default
#
# Copyright 2011, Infochimps, Inc.
#
# All rights reserved - Do Not Redistribute
#

include_recipe "flume"

package "flume-node"

provide_service ("#{node[:flume][:cluster_name]}-flume-node")
