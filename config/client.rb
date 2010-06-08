# Author:: Adam Jacob <adam@opscode.com>
# Author:: Joshua Timberman <joshua@opscode.com>
# Author:: Philip (flip) Kromer <flip@infochimps.org>
#
# Copyright 2009-2010, Opscode, Inc
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
# Chef Client Config File: /etc/chef/client.rb
# Automatically grabs configuration from ohai ec2 metadata.
#
# Sets the node's name after its cluster role

require 'ohai'
require 'json'

OHAI_INFO = Ohai::System.new
OHAI_INFO.all_plugins

log_level            :info
log_location         STDOUT
Mixlib::Log::Formatter.show_time = true
validation_key       "/etc/chef/validation.pem"
client_key           "/etc/chef/client.pem"
CHEF_CONFIG_FILE   = "/etc/chef/client-config.json"

# Extract client configuration from EC2 user-data and from local file
user_data   = OHAI_INFO[:ec2][:userdata]
chef_config           = JSON.parse(user_data).to_mash                  rescue {'attributes'=>{}}.to_mash
chef_config_from_file = JSON.load(File.open(CHEF_CONFIG_FILE)).to_mash rescue Mash.new
chef_config['attributes'].merge!(chef_config_from_file.to_mash)
p [chef_config]

# How to identify node to chef server.
chef_server_url        chef_config["chef_server"]            || 'http://localhost:4000'
validation_client_name chef_config["validation_client_name"] || 'chef-validator'

#
# Cluster index
#
cluster_role_index = chef_config["attributes"]["cluster_role_index"]
begin
  if chef_config["get_name_from_broham"] && (not cluster_role_index)
    require 'broham'
    Broham.establish_connection(:access_key => chef_config["aws"]["access_key"], :secret_access_key => chef_config["aws"]["secret_access_key"])
    cluster_role_conf  = Broham.register_as_next("#{chef_config["cluster_name"]}-#{chef_config["cluster_role"]}")
    cluster_role_index = [cluster_role_conf["idx"]].flatten.first
  end
rescue Exception => e ; warn "Error getting cluster role from broham: #{e.message}\n#{e.backtrace}" ; end
cluster_role_index ||= OHAI_INFO[:ec2][:ami_launch_index]
chef_config["attributes"]["cluster_role_index"] = cluster_role_index

# Node Name: if the node_name is given, use that;
# if the cluster name, cluster role (and optional index) are given, use
# "cluster-role-index";
# otherwise, use the instance_id.
case
when chef_config["attributes"]["node_name"]    then node_name chef_config["attributes"]["node_name"]
when chef_config["attributes"]["cluster_role"] then node_name [chef_config["attributes"]["cluster_name"], chef_config["attributes"]["cluster_role"], cluster_role_index.to_s].compact.join("-")
else                                                node_name OHAI_INFO[:ec2][:instance_id]
end
chef_config["attributes"]["node_name"] = node_name

# If the client file is missing, write the validation key out so chef-client can register
if (not File.exists?("/etc/chef/client.pem")) && (not File.exists?(validation_key)) && (not chef_config["validation_key"].blank?)
  File.open(validation_key, "w", 0600) do |f|
    f.print(chef_config["validation_key"])
  end
end

# Adopt chef config settings from the attributes key
unless File.exists?(CHEF_CONFIG_FILE)
  File.open(CHEF_CONFIG_FILE, "w", 0600) do |f|
    f.print(JSON.pretty_generate(chef_config["attributes"]))
  end
end
json_attribs CHEF_CONFIG_FILE if File.exists?(CHEF_CONFIG_FILE)
