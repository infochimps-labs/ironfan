# Chef Client Config File
# Automatically grabs configuration from ohai ec2 metadata.

require 'ohai'
require 'json'

o = Ohai::System.new
o.all_plugins
chef_config = JSON.parse(o[:ec2][:userdata])
if chef_config.kind_of?(Array)
  chef_config = chef_config[o[:ec2][:ami_launch_index]]
end

log_level        :info
log_location     STDOUT
node_name        o[:ec2][:instance_id]
chef_server_url  chef_config["chef_server"]

unless File.exists?("/etc/chef/client.pem")
  File.open("/etc/chef/validation.pem", "w", 0600) do |f|
    f.print(chef_config["validation_key"])
  end
end

if chef_config.has_key?("attributes")
  File.open("/etc/chef/client-config.json", "w") do |f|
    f.print(JSON.pretty_generate(chef_config["attributes"]))
  end
  json_attribs "/etc/chef/client-config.json"
end

validation_key "/etc/chef/validation.pem"
validation_client_name chef_config["validation_client_name"]

Mixlib::Log::Formatter.show_time = true
