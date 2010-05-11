# Chef Client Config File
#
# Automatically grabs configuration from JSON contained in the ohai ec2 metadata
# and the /etc/chef/chef_config.json file.
#

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

#
# Cluster index
#
cluster_role_index = chef_config['cluster_role_index']
begin
  if chef_config['get_name_from_broham'] && (not cluster_role_index)
    require 'broham'
    Broham.establish_connection(:access_key => chef_config['aws']['access_key'], :secret_access_key => chef_config['aws']['secret_access_key'])
    cluster_role_conf  = Broham.register_as_next("#{chef_config["cluster_name"]}-#{chef_config["cluster_role"]}")
    cluster_role_index = [cluster_role_conf['idx']].flatten.first
  end
rescue Exception => e
  warn [e.to_s, e.backtrace].flatten.compact.join("\n")
end
cluster_role_index ||= OHAI_INFO[:ec2][:ami_launch_index]
chef_config['cluster_role_index'] = cluster_role_index

# Node Name: if the node_name is given, use that;
# if the cluster name, cluster role (and optional index) are given, use
# "cluster-role-index";
# otherwise, use the instance_id.
case
when chef_config["node_name"]    then node_name chef_config["node_name"]
when chef_config["cluster_role"] then node_name [chef_config["cluster_name"], chef_config["cluster_role"], cluster_role_index.to_s].compact.join('-')
else                                  node_name OHAI_INFO[:ec2][:instance_id]
end
chef_config['node_name'] = node_name

# If the client file is missing, write the validation key out so chef-client
# can register
if (not File.exists?("/etc/chef/client.pem")) && (not File.exists?(validation_key))
  File.open(validation_key, "w", 0600) do |f|
    f.print(chef_config['chef']["validation_key"])
  end
end

# Adopt chef config settings from the attributes key
unless File.exists?(CHEF_CONFIG_FILE)
  File.open(CHEF_CONFIG_FILE, "w", 0600) do |f|
    f.print(JSON.pretty_generate(chef_config))
  end
end
json_attribs CHEF_CONFIG_FILE if File.exists?(CHEF_CONFIG_FILE)
