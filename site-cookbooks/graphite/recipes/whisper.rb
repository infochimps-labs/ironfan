#
# Cookbook Name::       graphite
# Description::         Whisper
# Recipe::              whisper
# Author::              Heavy Water Software Inc.
#
# Copyright 2011, Heavy Water Software Inc.
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

include_recipe "runit"

install_from_release('whisper') do
  version       node[:graphite][:whisper][:version]
  release_url   node[:graphite][:whisper][:release_url]
  home_dir      node[:graphite][:whisper][:home_dir]
  checksum      node[:graphite][:whisper][:release_url_checksum]
  action        [:install_python]
  not_if{ File.exists?("/usr/local/lib/python2.6/dist-packages/whisper-#{node[:graphite][:whisper][:version]}.egg-info") }
end
