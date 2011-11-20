#
# Cookbook Name::       mountable_volumes
# Description::         Placeholder recipe for mountable volumes integration
# Recipe::              default
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2011, Philip (flip) Kromer, infochimps.com
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

# cluster_chef_dashboard('mountable_volumes') do
#
# end

include_recipe 'cluster_chef'

# define(:cluster_chef_dashboard, :template_name => nil, :cookbook => nil, :variables => nil)
params = { :name => :mountable_volumes}
params[:template_name] ||= params[:name]

directory ::File.join(node[:cluster_chef][:conf_dir], 'dashboard') do
  owner         "root"
  group         "root"
  mode          "0755"
  action        :create
  recursive     true
end

template ::File.join(node[:cluster_chef][:conf_dir], 'dashboard', "#{params[:template_name]}.html") do
  source        "dashboard_snippet-#{params[:template_name]}.html.erb"
  owner         "root"
  group         "root"
  mode          "0644"
  cookbook      params[:cookbook]  if params[:cookbook]
  variables     params[:variables] ? params[:variables] : node[ params[:name] ]
  action        :create
end
