#
# Cookbook Name::       cassandra
# Description::         Base configuration for cassandra
# Recipe::              default
# Author::              Benjamin Black (<b@b3k.us>)
#
# Copyright 2010, Benjamin Black
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

# == Recipes

include_recipe "metachef"
include_recipe "volumes"
include_recipe "java" ; complain_if_not_sun_java(:cassandra)
include_recipe "thrift"

# == Packages

gem_package 'cassandra'
gem_package 'avro'

# == Users

daemon_user(:cassandra) do
  create_group  false
end

# == Directories

standard_dirs('cassandra') do
  directories   [:conf_dir, :log_dir, :lib_dir, :pid_dir, :data_dirs, :commitlog_dir, :saved_caches_dir]
  group         'root'
end
