#
# Cookbook Name:: jenkins
# Based on hudson
# Recipe:: build_from_github
#
# Author:: Philip (flip) Kromer <flip@infochimps.com>
#
# Copyright 2010, Infochimps, Inc
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

include_recipe 'build_from_github'

jenkins_plugins = %w[ github-oauth ]
unless jenkins_plugins.all?{|jplg| node[:jenkins][:server][:plugins].include?(jplg) }
  node[:jenkins][:server][:plugins] = (node[:jenkins][:server][:plugins] + jenkins_plugins).uniq
  node.save
end

