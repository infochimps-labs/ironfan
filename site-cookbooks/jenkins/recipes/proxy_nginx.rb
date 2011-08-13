#
# Cookbook Name:: jenkins
# Recipe:: proxy_nginx
#
# Author:: Fletcher Nichol <fnichol@nichol.ca>
#
# Copyright 2011, Fletcher Nichol
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

include_recipe "nginx::source"

if node[:jenkins][:http_proxy][:www_redirect] == "enable"
  www_redirect = true
else
  www_redirect = false
end

host_name = node[:jenkins][:http_proxy][:host_name] || node[:fqdn]

template "#{node[:nginx][:dir]}/sites-available/jenkins.conf" do
  source      "nginx_jenkins.conf.erb"
  owner       'root'
  group       'root'
  mode        '0644'
  variables(
    :host_name        => host_name,
    :host_aliases     => node[:jenkins][:http_proxy][:host_aliases],
    :listen_ports     => node[:jenkins][:http_proxy][:listen_ports],
    :www_redirect     => www_redirect,
    :max_upload_size  => node[:jenkins][:http_proxy][:client_max_body_size]
  )

  if File.exists?("#{node[:nginx][:dir]}/sites-enabled/jenkins.conf")
    notifies  :restart, 'service[nginx]'
  end
end

nginx_site "jenkins.conf" do
  if node[:jenkins][:http_proxy][:variant] == "nginx"
    enable true
  else
    enable false
  end
end
