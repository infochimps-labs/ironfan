#
# Author:: Dhruv Bansal (<dhruv@infochimps.org>)
# Cookbook Name:: azkaban
# Recipe:: default
#
# Copyright 2010, Dhruv Bansal
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
include_recipe "runit"

user "azkaban" do
  uid       '332'
  gid       "nogroup"
  shell     "/bin/false"
  action    :create
  not_if{ node[:etc][:passwd] && node[:etc][:passwd]['azkaban'] }
end

[node[:azkaban][:log_dir], node[:azkaban][:job_dir]].each do |azkaban_dir|
  directory azkaban_dir do
    owner    "azkaban"
    group    "admin"
    mode     "0755"
    action   :create
    recursive true
  end
end

include_recipe "azkaban::install_from_release"
runit_service "azkaban"
include_recipe "azkaban::post_deploy" if recipe?("azkaban::post_deploy")
