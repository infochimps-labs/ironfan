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

remote_file "/tmp/mx4j.zip" do
  source node[:cassandra][:mx4j_url]
  mode "0644"
  action :create
end

package "unzip"

bash "unzip_mx4j" do
  code <<EOF
  unzip -d /usr/local/share /tmp/mx4j.zip
EOF
  not_if {system("ls -d /usr/local/share/mx4j-* > /dev/null")}
end

jarpath = "#{node[:cassandra][:cassandra_home]}/lib/mx4j-tools.jar"

# We don't use the link resource since we're doing a wildcard
bash "link_mx4j_tools_jar" do
  code <<EOF
  ln -sf /usr/local/share/mx4j-*/lib/mx4j-tools.jar #{jarpath}
EOF

  notifies  :restart, resources(:service => "cassandra")
  not_if {File.exist?(jarpath)}
end

# XXX: How to conditionally set this after the jarfile link has been
# put in place?
node[:cassandra][:enable_mx4j] = true
