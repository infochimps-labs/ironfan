#
# Cookbook Name::       elasticsearch
# Description::         Http
# Recipe::              http
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

include_recipe "nginx"

template File.join(node[:nginx][:dir], "sites-available", "elasticsearch.conf") do
  source "elasticsearch.nginx.conf.erb"
  action :create
end

nginx_site "elasticsearch.conf" do
  action :enable
end

load_balancer   node[:elasticsearch][:load_balancer] if node[:elasticsearch][:load_balancer]
provide_service("#{node[:elasticsearch][:cluster_name]}-http_esnode")
