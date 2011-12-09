#
# Cookbook Name::       jruby
# Description::         Base configuration for jruby
# Recipe::              default
# Author::              Jacob Perkins - Infochimps, Inc
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

include_recipe 'java'

install_from_release('jruby') do
  release_url   node[:jruby][:release_url]
  home_dir      node[:jruby][:home_dir]
  version       node[:jruby][:version]
  action        [ :install ]
  has_binaries  %w[ bin/jruby bin/jrubyc bin/jruby.rb bin/jirb ]
  environment('JAVA_HOME' => node[:java][:java_home]) if node[:java][:java_home]
  not_if{ ::File.exists?("#{node[:jruby][:install_dir]}/jruby.jar") }
end

directory File.join(node[:jruby][:home_dir], 'bin') do
  owner     'root'
  group     'root'
  mode      '0755'
  action    :create
end

template File.join(node[:jruby][:home_dir], 'bin/chef-jgem') do
  source        "chef-jgem.erb"
  variables     :jruby => node[:jruby]
  owner         "root"
  mode          "0755"
end
