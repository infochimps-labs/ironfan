#
# Cookbook Name::       pig
# Description::         Install From Package
# Recipe::              install_from_package
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2009, Opscode, Inc.
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

include_recipe "apt"
include_recipe "pig::default"

#
# Add Cloudera Apt Repo
#

# Get the archive key for cloudera package repo
execute "curl -s http://archive.cloudera.com/debian/archive.key | apt-key add -" do
  not_if "apt-key export 'Cloudera Apt Repository' | grep 'BEGIN PGP PUBLIC KEY'"
  notifies :run, "execute[apt-get update]"
end

# Add cloudera package repo
apt_repository 'cloudera' do
  uri             'http://archive.cloudera.com/debian'
  distro        = node[:lsb][:codename]
  distribution    "#{distro}-#{node[:hadoop][:cdh_version]}"
  components      ['contrib']
  key             "http://archive.cloudera.com/debian/archive.key"
  action          :add
end

#
# Install package
#

package "hadoop-pig"

# why does this need to be here?
link "/usr/local/bin/pig" do
  to          File.join(node[:pig][:home_dir], 'bin', 'pig')
  action      :create
end
