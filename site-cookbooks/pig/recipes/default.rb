#
# Cookbook Name::       pig
# Description::         Base configuration for pig
# Recipe::              default
# Author::              Philip (flip) Kromer - Infochimps, Inc
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

unless( node['java']['install_flavor'] == 'sun')
  warn "Warning!! You are *strongly* recommended to use Sun Java for pig. Set node['java']['install_flavor'] = 'sun' in a role -- right now it's '#{node['java']['install_flavor']}'"
end

include_recipe "install_from"
include_recipe "java"
