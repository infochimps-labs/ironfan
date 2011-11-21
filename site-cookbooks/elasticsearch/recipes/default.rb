#
# Cookbook Name::       elasticsearch
# Description::         Base configuration for elasticsearch
# Recipe::              default
# Author::              GoTime, modifications by Infochimps
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

include_recipe "aws"
include_recipe "java::sun"
include_recipe "runit"
include_recipe "mountable_volumes"

daemon_user(:elasticsearch) do
  create_group  true
end

# group "elasticsearch" do
#   group_name 'elasticsearch'
#   gid         61021
#   action      [:create, :manage]
# end
#
# user "elasticsearch" do
#   uid         61021
#   gid         "elasticsearch"
# end

#
# Set up Config directory and files
#

directory node[:elasticsearch][:conf_dir] do
  owner         "root"
  group         "root"
  mode          0755
end

template "/etc/elasticsearch/logging.yml" do
  source        "logging.yml.erb"
  mode          0644
end

template "/etc/elasticsearch/elasticsearch.in.sh" do
  source        "elasticsearch.in.sh.erb"
  mode          0644
end

elasticsearch_seeds  = [node[:elasticsearch][:seeds]]
elasticsearch_seeds += all_provider_private_ips(node[:elasticsearch][:cluster_name]+"-data_esnode") rescue []
template "/etc/elasticsearch/elasticsearch.yml" do
  source        "elasticsearch.yml.erb"
  owner         "elasticsearch"
  group         "elasticsearch"
  mode          0644
  variables(
    :elasticsearch_seeds => elasticsearch_seeds.flatten.reject(&:nil?).uniq
    )
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
        recursive   true
      end
    end
  end
end
