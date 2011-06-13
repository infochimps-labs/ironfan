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
ssl_verify_mode      :verify_none
file_cache_path      "/var/cache/chef"
pid_file             "/var/run/chef/client.pid"
cache_options({ :path => "/var/cache/chef/checksums", :skip_expires => true})
signing_ca_user      "chef"

# Extract client configuration from EC2 user-data and from local file
CHEF_CONFIG_FILE      = "/etc/chef/chef-config.json"
CLIENT_CONFIG_FILE    = "/etc/chef/client-config.json"
user_data             = OHAI_INFO[:ec2][:userdata]
#chef_config           = JSON.parse(user_data).to_mash rescue {'attributes'=>{}}.to_mash
chef_config = {}
chef_config_from_file = JSON.load(File.open(CHEF_CONFIG_FILE))   rescue {}
chef_config.merge!(chef_config_from_file)
attrs                 = chef_config['attributes']
attrs_from_file       = JSON.load(File.open(CLIENT_CONFIG_FILE)) rescue {}
attrs.merge!(attrs_from_file)

# How to identify node to chef server.
chef_server_url        chef_config["chef_server"]            || 'http://localhost:4000'
validation_client_name chef_config["validation_client_name"] || 'chef-validator'
validation_key         "/etc/chef/validation.pem"
client_key             "/etc/chef/client.pem"

#
# Find the cluster name, role and index
# and use it to set the node_name
#
if chef_config['get_name_from'] == 'broham'
  puts "Getting name from broham within [#{attrs['cluster_name']}-#{attrs['cluster_role']}]" if attrs['node_name'].blank?
  begin
    require 'broham'
    BrohamNode.set_cluster_info!(attrs)
    attrs["facet_index"] ||= attrs["cluster_role_index"]
  rescue Exception => e ; warn "Error getting cluster role from broham: #{e.message}\n#{e.backtrace}" ; end
end
attrs["facet_index"] ||= OHAI_INFO[:ec2][:instance_id]
attrs["node_name"]   ||= [ attrs["cluster_name"], attrs["cluster_role"], attrs["facet_index"] ].reject(&:blank?).join('-')
node_name attrs["node_name"]

# If the client file is missing, write the validation key out so chef-client can register
if (not File.exists?("/etc/chef/client.pem")) && (not File.exists?(validation_key)) && (not chef_config["validation_key"].blank?)
  File.open(validation_key, "w", 0600) do |f|
    f.print(chef_config["validation_key"])
  end
end

# Adopt chef config settings from the attrs hash
unless File.exists?(CLIENT_CONFIG_FILE)
  File.open(CLIENT_CONFIG_FILE, "w", 0600) do |f|
    f.print(JSON.pretty_generate(attrs))
  end
end
json_attribs CLIENT_CONFIG_FILE if File.exists?(CLIENT_CONFIG_FILE)

puts "=> chef client #{node_name} on #{chef_server_url} in cluster '#{attrs["cluster_name"]}'"
