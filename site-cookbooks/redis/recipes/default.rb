#
# Author:: Benjamin Black (<b@b3k.us>)
# Cookbook Name:: redis
# Recipe:: default
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

# These are included explicitly until I can untangle the hellscape of
# dependencies on redis in the rest of our recipes
include_recipe 'redis::base'
include_recipe 'redis::install_from_package'
include_recipe 'redis::server'
