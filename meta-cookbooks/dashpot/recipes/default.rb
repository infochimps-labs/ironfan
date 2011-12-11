#
# Cookbook Name::       dashpot
# Description::         Dashboard for this machine: index of services and their dashboard snippets
# Recipe::              default
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer - Infochimps, Inc
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

include_recipe  'metachef'

standard_dirs(:dashpot) do
  directories  :home_dir, :log_dir, :conf_dir
end

#
# Dashboard Dashboard
#

dashpot_dashboard(:dashpot) do
  template_name 'index'
  action        :create
  summary_keys = %w[]
  variables     :summary_keys => summary_keys, :dashpot => node[:dashpot]
end
