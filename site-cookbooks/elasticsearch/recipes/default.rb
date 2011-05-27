#
# Cookbook Name:: elasticsearch
# Recipe:: default
#
# Copyright 2010, GoTime
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

include_recipe "java"

# Tell ElasticSearch where to find its other nodes
provide_service "#{node[:cluster_name]}-elasticsearch"
if node[:elasticsearch][:seeds].blank?
    node[:elasticsearch][:seeds] = all_provider_private_ips("#{node[:cluster_name]}-elasticsearch").sort().map { |ip| ip+':9300' }
end

group "elasticsearch" do
  group_name 'elasticsearch'
  gid         61021
  action      [:create, :manage]
end

user "elasticsearch" do
  uid         61021
  gid         "elasticsearch"
end

#
# Set up Config directory and files
#

["/etc/elasticsearch"].each do |dir|
  directory dir do
    owner         "root"
    group         "root"
    mode          0755
  end
end

template "/etc/elasticsearch/logging.yml" do
  source        "logging.yml.erb"
  mode          0644
end

template "/etc/elasticsearch/elasticsearch.in.sh" do
  source        "elasticsearch.in.sh.erb"
  mode          0644
end

template "/etc/elasticsearch/elasticsearch.yml" do
  source        "elasticsearch.yml.erb"
  owner         "elasticsearch"
  group         "elasticsearch"
  mode          0644
end

#
# Set up ancilliary directories
#

["/var/lib/elasticsearch", "/var/run/elasticsearch"].each do |dir|
  directory dir do
    owner       "elasticsearch"
    group       "elasticsearch"
    mode        0755
  end
end

directory "/var/log/elasticsearch" do
  owner         "elasticsearch"
  group         "www-data"
  mode          0775
  action        :create
  recursive     true
end

if node[:ec2]
  node[:elasticsearch][:local_disks].each do |mnt, dev|
    ["elasticsearch/data","elasticsearch/work"].each do |dir|
      directory "#{mnt}/#{dir}" do
        owner       "elasticsearch"
        group       "elasticsearch"
        mode        0755
        recursive
      end
    end
  end
end
