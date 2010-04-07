# Chef Client Config File
# Automatically grabs configuration from ohai ec2 metadata.

require 'ohai'
require 'json'

OHAI_INFO = Ohai::System.new
OHAI_INFO.all_plugins

log_level            :info
log_location         STDOUT
validation_key       "/etc/chef/validation.pem"
client_key           "/etc/chef/client.pem"
CHEF_CONFIG_FILE   = "/etc/chef/chef_config.json"
file_cache_path      "/srv/chef/cache"
pid_file             "/var/run/chef/chef-client.pid"
Mixlib::Log::Formatter.show_time = true

# Extract client configuration from EC2 user-data and from local file
user_data   = OHAI_INFO[:ec2][:userdata]
chef_config_from_user_data = JSON.parse(user_data)                  rescue {}
chef_config_from_file      = JSON.load(File.open(CHEF_CONFIG_FILE)) rescue {}
chef_config = chef_config_from_user_data.to_mash.merge(chef_config_from_file)

# How to identify node to chef server.
chef_server_url        chef_config['chef']['chef_server']
validation_client_name chef_config['chef']['validation_client_name']

# Cluster index
cluster_role_index = chef_config['cluster_role_index']
begin
  if ! cluster_role_index
    require 'broham'
    Settings.access_key        = chef_config['aws']['access_key']
    Settings.secret_access_key = chef_config['aws']['secret_access_key']
    Broham.establish_connection
    broham_service = [chef_config["cluster_name"], chef_config["cluster_role"]].join('-')
    cluster_role_conf  = Broham.register_as_next broham_service
    p [cluster_role_conf]
    cluster_role_index = [cluster_role_conf['idx']].flatten.first
  end
  cluster_role_index ||= OHAI_INFO[:ec2][:ami_launch_index]
rescue Exception => e
  warn [e.to_s, e.backtrace].flatten.compact.join("\n")
end
cluster_role_index ||= OHAI_INFO[:ec2][:ami_launch_index]
chef_config['cluster_role_index'] = cluster_role_index

# Node Name: if the node_name is given, use that; if the cluster name, cluster
#   role (and optional index) are given, use "cluster-role-index" otherwise,
#   use the instance_id.
case
when chef_config["node_name"]    then node_name chef_config["node_name"]
when chef_config["cluster_role"] then node_name [chef_config["cluster_name"], chef_config["cluster_role"], cluster_role_index.to_s].compact.join('-')
else                                  node_name OHAI_INFO[:ec2][:instance_id]
end
chef_config['node_name'] = node_name

# If the client file is missing, write the validation key out so chef-client
# can register
if not File.exists?("/etc/chef/client.pem")
  File.open(validation_key, "w", 0600) do |f|
    f.print(chef_config['chef']["validation_key"])
  end
elsif File.exists?(validation_key)
  require 'fileutils'
  FileUtils.rm(validation_key) rescue nil
end

# Adopt chef config settings from the attributes key
if not File.exists?(CHEF_CONFIG_FILE)
  chef_config_out = chef_config.reject{|k,v| ["run_list", "chef"].include?(k.to_s) }
  File.open(CHEF_CONFIG_FILE, "w", 0600) do |f|
    f.puts(%Q{// Use this file to override the user-data attributes})
    f.print(JSON.pretty_generate(chef_config_out))
  end
end

json_attribs CHEF_CONFIG_FILE if File.exists?(CHEF_CONFIG_FILE)
