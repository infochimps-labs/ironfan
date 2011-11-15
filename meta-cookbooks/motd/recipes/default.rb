#
# Cookbook Name::       motd
# Description::         Base configuration for motd
# Recipe::              default
# Author::              Dhruv Bansal - Infochimps, Inc
#
# Copyright 2011, Dhruv Bansal - Infochimps, Inc
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
# Set the Message of the day (motd) file
#

link '/etc/motd' do
  action :delete
  only_if{ File.symlink?('/etc/motd') }
end

def get_silly
  svcs = (node[:provides_service] || {}).keys
  case
  when (! svcs.grep(/chef_server/).empty?)           then "BORK BORK BORK"
  when (! svcs.grep(/hadoop/).empty?)                then "CRUNCH CRUNCH CRUNCH"
  when (! svcs.grep(/scrape/).empty?)                then "SCRAPE SCRAPE SCRAPE"
  when (! svcs.grep(/hbase|redis|cassandra/).empty?) then "DATA DATA DATA DATA DATA"
  when (! svcs.grep(/search/).empty?)                then "FIND FIND FIND"
  when (! svcs.grep(/resque|queue|jenkins/).empty?)  then "ZUG ZUG ZUG"
  when (! svcs.grep(/staging/).empty?)               then "STAGE STAGE STAGE"
  when (! svcs.grep(/flume/).empty?)                 then "ROW ROW ROW"
  when (! svcs.grep(/apache|nginx|web/).empty?)      then "SERVE SERVE SERVE"
  else                                                    "OOK OOK OOK"
  end
end

motd_vars = {}
motd_vars[:roles]            = node[:roles] || []
motd_vars[:silliness]        = get_silly

[ :instance_id, :instance_type, :public_hostname, ].each{|v| motd_vars[v] = (node[:ec2]   || {})[v] || '' }
[ :security_groups,                               ].each{|v| motd_vars[v] = (node[:ec2]   || {})[v] || [] }
[ :private_ips, :public_ips                       ].each{|v| motd_vars[v] = (node[:cloud] || {})[v] || [] }
[ :description                                    ].each{|v| motd_vars[v] = (node[:lsb]   || {})[v] || '' }

template "/etc/motd" do
  owner  "root"
  mode   "0644"
  source "motd.erb"
  variables(motd_vars)
end

# Put the node name in a file for other processes to read easily
template "/etc/node_name" do
  mode 0644
  source "node_name.erb"
end
