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
require 'extlib'

CHEF_CONFIG_FILE      = "/etc/chef/chef-config.json"
NODE_ATTRIBUTES_FILE  = "/etc/chef/node-attrs.json"
FIRST_BOOT_FILE       = "/etc/chef/first-boot.json"

def populate_if_empty(filename, str)
  unless File.exists?(filename)
    puts "Populating #{filename}" ;
    File.open(filename, "w", 0600){|f| f.puts(str) }
  end
end

def merge_if_present hsh
  hsh.merge!( yield ) rescue {}
end

#
# Load configuration
#

# Assume it's the first run if we've ever generated the attributes file
IS_FIRST_BOOT = ! File.exists?(NODE_ATTRIBUTES_FILE)

# Start with a set of defaults
chef_config = {
  :chef_server            => 'http://localhost:4000',
  :validation_client_name => 'chef-validator',
  :attributes => {},
}.to_mash

# Extract client configuration from an override file (if present), from EC2 user-data otherwise
if File.exists?(CHEF_CONFIG_FILE)
  merge_if_present(chef_config){ JSON.load(File.open(CHEF_CONFIG_FILE)) }
else
  OHAI_INFO = Ohai::System.new
  OHAI_INFO.all_plugins
  merge_if_present(chef_config){ JSON.parse(OHAI_INFO[:ec2][:userdata]) }
end
# Merge in the saved node attributes, if present
if File.exists?(NODE_ATTRIBUTES_FILE)
  merge_if_present(chef_config){ {:attributes => JSON.load(File.open(NODE_ATTRIBUTES_FILE))} }
end

puts JSON.pretty_generate(chef_config.except(:validation_key))

#
# Configure chef run
#

log_level              :info
log_location           STDOUT
node_name              chef_config[:attributes][:node_name]
chef_server_url        chef_config[:chef_server]
validation_client_name chef_config[:validation_client_name]
validation_key         "/etc/chef/validation.pem"
client_key             "/etc/chef/client.pem"
Deprecate.skip = true # hey rubygems please don't deprecate all over my screen

# If the client file is missing, write the validation key out so chef-client can register
unless File.exists?("/etc/chef/client.pem") || chef_config[:validation_key].blank?
  populate_if_empty(validation_key, chef_config[:validation_key])
end

# Load the node_attributes_file
populate_if_empty(NODE_ATTRIBUTES_FILE, JSON.pretty_generate(chef_config[:attributes].except(:validation_key, :run_list)))
json_attribs NODE_ATTRIBUTES_FILE if File.exists?(NODE_ATTRIBUTES_FILE)

# If it's the first run, load the node_attributes_file
if IS_FIRST_BOOT
  puts "First run! Loading initial attributes from #{FIRST_BOOT_FILE}"
  populate_if_empty(FIRST_BOOT_FILE, JSON.pretty_generate(chef_config[:attributes].except(:validation_key)))
  json_attribs FIRST_BOOT_FILE
end

puts JSON.pretty_generate(chef_config.except(:validation_key))
puts "=> chef client #{node_name} on #{chef_server_url} in cluster '#{chef_config[:attributes][:cluster_name]}'"
