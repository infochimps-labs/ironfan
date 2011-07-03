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
require 'extlib/mash'

CHEF_CONFIG_FILE      = "/etc/chef/chef-config.json"
NODE_ATTRIBUTES_FILE  = "/etc/chef/node-attrs.json"
FIRST_BOOT_FILE       = "/etc/chef/first-boot.json"

# Start with a set of defaults                                                                                                                                                                                                                                                
chef_config = {
  :chef_server            => 'http://localhost:4000',
  :validation_client_name => 'chef-validator',
  :attributes => {},
}.to_mash

# Extract client configuration from an override file (if present), from EC2 user-data otherwise                                                                                                                                                                               
if File.exists?(CHEF_CONFIG_FILE)
  config_from_file = JSON.load(File.open(CHEF_CONFIG_FILE)) rescue {}
  chef_config.merge!(config_from_file)
else
  OHAI_INFO = Ohai::System.new
  OHAI_INFO.all_plugins
  config_from_userdata = JSON.parse(OHAI_INFO[:ec2][:userdata]) rescue {}
  chef_config.merge!(config_from_userdata)
end

# Merge in the saved node attributes, if present
if File.exists?(NODE_ATTRIBUTES_FILE)
  config_from_file = JSON.load(File.open(NODE_ATTRIBUTES_FILE)) rescue {}
  chef_config[:attributes].merge!(config_from_file)
end

# Configure chef run                                                                                                                                                                                                                                                          
log_level              :info
log_location           STDOUT
node_name              chef_config[:attributes][:node_name]
chef_server_url        chef_config[:chef_server]
validation_client_name chef_config[:validation_client_name]
validation_key         "/etc/chef/validation.pem"
client_key             "/etc/chef/client.pem"
Deprecate.skip = true # hey rubygems please don't deprecate all over my screen

# If the client file is missing, write the validation key out so chef-client can register                                                                                                                                                                                     
if (not chef_config[:validation_key].blank?) && (not File.exists?("/etc/chef/client.pem")) && (not File.exists?(validation_key))
  File.open(validation_key, "w", 0600) do |f|
    f.print(chef_config[:validation_key])
  end
end

# If the node_attributes_file is missing, this is our initial run.
unless File.exists?(NODE_ATTRIBUTES_FILE)
  # save the node attributes to an override file,                                                                                                                                                                                                                                       
  puts "First run! Saving attributes to #{NODE_ATTRIBUTES_FILE}"
  File.open(NODE_ATTRIBUTES_FILE, "w", 0600) do |f|
    f.print(JSON.pretty_generate(chef_config[:attributes]))
  end
  # and load first boot if any                                                                                                                                                                                                                                                
  if File.exists?(FIRST_BOOT_FILE)
    puts "Loading initial attributes from #{FIRST_BOOT_FILE}"
    json_attribs FIRST_BOOT_FILE
  end
end

# Load the node_attributes_file
json_attribs NODE_ATTRIBUTES_FILE if File.exists?(NODE_ATTRIBUTES_FILE)

# puts JSON.pretty_generate(chef_config)
puts "=> chef client #{node_name} on #{chef_server_url} in cluster '#{chef_config[:attributes][:cluster_name]}'"
