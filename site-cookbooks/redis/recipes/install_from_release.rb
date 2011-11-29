#
# Cookbook Name::       redis
# Description::         Install From Release
# Recipe::              install_from_release
# Author::              Benjamin Black
#
# Copyright 2009, Infochimps, Inc.
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

include_recipe "install_from"

install_from_release('redis') do
  release_url  node[:redis][:release_url]
  home_dir     node[:redis][:home_dir]
  version      node[:redis][:version]
  action       [ :install, :install_with_make ]
  not_if{ File.exists?(File.join(node[:redis][:home_dir], 'redis-server')) }
end
