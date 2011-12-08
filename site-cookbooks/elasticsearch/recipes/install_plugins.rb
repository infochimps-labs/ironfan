#
# Cookbook Name::       elasticsearch
# Description::         Install Plugins
# Recipe::              install_plugins
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

directory "#{node[:elasticsearch][:home_dir]}/plugins" do
  owner         "root"
  group         "root"
  mode          0755
end

node[:elasticsearch][:plugins].each do |plugin|
  bash "install #{plugin} plugin for elasticsearch" do
    user          "root"
    cwd           "#{node[:elasticsearch][:home_dir]}"
    code          "./bin/plugin -install #{plugin}"
    not_if{ File.exist?("#{node[:elasticsearch][:home_dir]}/plugins/#{plugin}")  }
  end
end
