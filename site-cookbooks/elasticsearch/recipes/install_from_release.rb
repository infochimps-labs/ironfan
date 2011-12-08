#
# Cookbook Name::       elasticsearch
# Description::         Install From Release
# Recipe::              install_from_release
# Author::              GoTime, modifications by Infochimps
#
# Copyright 2011, GoTime, modifications by Infochimps
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

install_from_release(:elasticsearch) do
  release_url   node[:elasticsearch][:release_url]
  home_dir      node[:elasticsearch][:home_dir]
  version       node[:elasticsearch][:version]
  checksum      node[:elasticsearch][:checksum]
  action        [ :install ]
  has_binaries  [ 'bin/elasticsearch' ]
  not_if{ ::File.exists?("#{node[:elasticsearch][:home_dir]}/bin/elasticsearch") }
end
