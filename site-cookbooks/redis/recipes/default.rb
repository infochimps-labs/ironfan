#
# Cookbook Name::       redis
# Description::         Base configuration for redis
# Recipe::              default
# Author::              Benjamin Black (<b@b3k.us>)
#
# Copyright 2009, Benjamin Black
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

directory "/var/log/redis" do
  owner     "redis"
  group     "redis"
  mode      "0755"
  action    :create
end

directory node[:redis][:data_dir] do
  owner     "redis"
  group     "redis"
  mode      "0755"
  action    :create
  recursive true
end

directory "/etc/redis" do
  owner     "root"
  group     "root"
  mode      "0755"
  action    :create
end
