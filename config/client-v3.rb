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

#
# Load configuration
#

def merge_safely hsh
  hsh.merge!( yield ) rescue {}
end

def create_file_if_empty(filename, str)
  unless File.exists?(filename)
    puts "Populating #{filename}" ;
    File.open(filename, "w", 0600){|f| f.puts(str) }
  end
end

# Start with a set of defaults
chef_config = {
  :chef_server            => 'http://localhost:4000',
  :validation_client_name => 'chef-validator',
  :attributes             => {},
}.to_mash

# Extract client configuration from EC2 user-data
OHAI_INFO = Ohai::System.new
OHAI_INFO.all_plugins 
merge_safely(chef_config){ JSON.parse(OHAI_INFO[:ec2][:userdata]) }

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

# If the client file is missing, write the validation key out so chef-client can register
unless File.exists?(client_key) || chef_config[:validation_key].nil? || chef_config[:validation_key].to_s.empty?
  create_file_if_empty(validation_key, chef_config[:validation_key])
end

puts "=> chef client #{node_name} on #{chef_server_url} in cluster '#{chef_config[:attributes][:cluster_name]}'"
