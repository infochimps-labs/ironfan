#
# Cookbook Name::       graphite
# Description::         Base configuration for graphite
# Recipe::              default
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

include_recipe "python"
include_recipe 'metachef'

daemon_user(:graphite)

standard_dirs('graphite') do
  directories   :conf_dir, :home_dir, :log_dir
end

# Data onto a bulk device
volume_dirs('graphite.whisper.data') do
  type          :persistent
  selects       :all
  path          'graphite/whisper/data'
  mode          "0700"
end
