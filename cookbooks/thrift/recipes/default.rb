#
# Cookbook Name:: thrift
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

version = node['thrift']['version']

include_recipe "build-essential"
include_recipe "boost"
include_recipe "python"

%w{ flex bison libtool autoconf pkg-config }.each do |pkg|
  package pkg
end

install_from_apache(:thrift) do
  version       node[:thrift][:version]
  checksum      node[:thrift][:checksum]
  home_dir      node[:thrift][:home_dir]
  action        [:configure_with_autoconf, :install_with_make]
  autoconf_opts node[:thrift]['configure_options']
  # not_if{ ::File.exists?("#{node[:thrift][:home_dir]}/thrift") }
end
