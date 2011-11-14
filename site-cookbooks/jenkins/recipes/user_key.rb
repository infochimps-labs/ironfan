#
# Cookbook Name::       jenkins
# Recipe::              user_key
# Author::              Fletcher Nichol
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

pkey = "#{node[:jenkins][:server][:home]}/.ssh/id_rsa"

user node[:jenkins][:server][:user] do
  home      node[:jenkins][:server][:home]
end

directory node[:jenkins][:server][:home] do
  recursive true
  owner     node[:jenkins][:server][:user]
  group     node[:jenkins][:server][:group]
end

directory "#{node[:jenkins][:server][:home]}/.ssh" do
  mode      "0700"
  owner     node[:jenkins][:server][:user]
  group     node[:jenkins][:server][:group]
  recursive true
  action    :create
end

execute "ssh-keygen -f #{pkey} -N ''" do
  user  node[:jenkins][:server][:user]
  group node[:jenkins][:server][:group]
  not_if { File.exists?(pkey) }
end

ruby_block "store jenkins ssh pubkey" do
  block do
    node.set[:jenkins][:server][:pubkey] = File.open("#{pkey}.pub") { |f| f.gets }
  end
end

Chef::Log.info ['pubkey', __FILE__]
