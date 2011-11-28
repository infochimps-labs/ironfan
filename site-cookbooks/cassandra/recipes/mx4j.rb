#
# Cookbook Name::       cassandra
# Description::         Mx4j
# Recipe::              mx4j
# Author::              Mike Heffner (<mike@librato.com>)
#
# Copyright 2011, Benjamin Black
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

#
# Installs the MX4J jarfile for monitoring
#
# See:
# http://wiki.apache.org/cassandra/Operations#Monitoring_with_MX4J
#
#

install_from_release(:mx4j) do
  release_url   node[:cassandra][:mx4j_release_url]
  home_dir      "/usr/local/share/mx4j"
  version       node[:cassandra][:mx4j_version]
  action        [:download, :unpack]
end

link "#{node[:cassandra][:home_dir]}/lib/mx4j-tools.jar" do
  to            "/usr/local/share/mx4j/lib/mx4j-tools.jar"
    notifies    :restart, "service[cassandra]", :delayed if startable?(node[:cassandra])
end

# FIXME: How to conditionally set this after the jarfile link has been  put in place?
node[:cassandra][:enable_mx4j] = true
