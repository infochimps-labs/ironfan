# Chef Client Config File

require 'ohai'
require 'json'

o = Ohai::System.new
o.all_plugins
chef_config = JSON.parse(o[:ec2][:userdata])
if chef_config.kind_of?(Array)
  chef_config = chef_config[o[:ec2][:ami_launch_index]]
end

log_level        :info
log_location     "/var/log/chef/client.log"
chef_server_url  chef_config["chef_server"]
registration_url chef_config["chef_server"]
openid_url       chef_config["chef_server"]
template_url     chef_config["chef_server"]
remotefile_url   chef_config["chef_server"]
search_url       chef_config["chef_server"]
role_url         chef_config["chef_server"]
client_url       chef_config["chef_server"]

node_name        o[:ec2][:instance_id]

unless File.exists?("/etc/chef/client.pem")
  File.open("/etc/chef/validation.pem", "w") do |f|
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
