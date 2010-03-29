# Chef Client Config File
# Automatically grabs configuration from ohai ec2 metadata.

require 'ohai'
require 'json'

o = Ohai::System.new
o.all_plugins
node_launch_index = o[:ec2][:ami_launch_index]
# if the node_name is given, use that;
# if the cluster_name is given, use 'cluster_name-node_launch_index';
# otherwise use the instance_id.
node_name = case
            when o[:node_name]    then o[:node_name]
            when o[:cluster_name] then [o[:cluster_name], node_launch_index].compact.join('-')
            else o[:ec2][:instance_id]
end

log_level       :info
log_location    STDOUT
validation_key  "/etc/chef/validation.pem"
client_key      "/etc/chef/client.pem"
ssl_verify_mode :verify_none
node_name        node_name
file_cache_path  "/srv/chef/cache"
pid_file         "/var/run/chef/chef-client.pid"
Mixlib::Log::Formatter.show_time = true

chef_config       = JSON.parse(o[:ec2][:userdata]) rescue nil
if ! chef_config.nil?  # Yays we got user-data to config with

  # If it's an array, assume it's for a robot army of similar machines, and
  # extract the setup accordingly.
  if chef_config.kind_of?(Array)
    chef_config = chef_config[node_launch_index]
  end

  chef_server_url        chef_config["chef_server"]
  validation_client_name chef_config["validation_client_name"]

  # If the client file is missing, write the validation key out so chef-client
  # can register
  unless File.exists?("/etc/chef/client.pem")
    File.open("/etc/chef/validation.pem", "w", 0600) do |f|
      f.print(chef_config["validation_key"])
    end
  end

  # Adopt chef config settings from the attributes key
  # for a different take on the same thing, see 37s_cookbooks' ec2/attributes/default.rb
  if chef_config.has_key?("attributes")
    File.open("/etc/chef/client-config.json", "w") do |f|
      f.print(JSON.pretty_generate(chef_config["attributes"]))
    end
    json_attribs "/etc/chef/client-config.json"
  end
else # no user-data ACK!
  chef_server_url        "http://chef.infinitemonkeys.info:4000"
  validation_client_name "chef-validator"
end
