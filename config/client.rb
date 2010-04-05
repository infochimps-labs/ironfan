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
file_cache_path      "/srv/chef/cache"
pid_file             "/var/run/chef/chef-client.pid"
Mixlib::Log::Formatter.show_time = true

CLIENT_CONFIG_FILE = "/etc/chef/client-config.json"
client_config = JSON.load(File.open(CLIENT_CONFIG_FILE)) rescue {}

# Extract client configuration from EC2 user-data
user_data   = OHAI_INFO[:ec2][:userdata]
chef_config = JSON.parse(user_data) rescue nil
p chef_config
chef_config = (chef_config||{}.to_mash).merge(:node_name => 'kong.infinitemonkeys.info')

if ! chef_config.nil?
  # How to identify node to chef server.
  chef_server_url        chef_config["chef_server"]            || "http://chef.infinitemonkeys.info:4000"
  validation_client_name chef_config["validation_client_name"] || "chef-validator"

  # Cluster index
  begin
    cluster_role_index = chef_config['cluster_role_index']
    if ! cluster_role_index
      require 'broham'
      Settings.access_key        = client_config['access_key']
      Settings.secret_access_key = client_config['secret_access_key']
      role = client_config["cluster_role"] || chef_config["cluster_role"]
      p [Settings]
      Broham.establish_connection
      Broham.create_domain
      cluster_role_conf  = Broham.register_as_next role
      p [cluster_role_conf]
      cluster_role_index = cluster_role_conf['idx']
      p [cluster_role_index]
    end
    cluster_role_index ||= OHAI_INFO[:ec2][:ami_launch_index]
  rescue Exception => e
    warn [e.to_s, e.backtrace].flatten.compact.join("\n")
  end

  # Node Name: if the node_name is given, use that; if the cluster name, cluster
  #   role (and optional index) are given, use "cluster-role-index" otherwise,
  #   use the instance_id.
  case
  when chef_config["node_name"]    then node_name chef_config["node_name"]
  when chef_config["cluster_role"] then node_name [chef_config["cluster_name"], chef_config["cluster_role"], cluster_role_index.to_s].compact.join('-')
  else                                  node_name OHAI_INFO[:ec2][:instance_id]
  end

  # If the client file is missing, write the validation key out so chef-client
  # can register
  if File.exists?("/etc/chef/client.pem")
    # File.rm(validation_key)
  else
    File.open(validation_key, "w", 0600) do |f|
      f.print(chef_config["validation_key"])
    end
  end

  # Adopt chef config settings from the attributes key
  if not File.exists?(CLIENT_CONFIG_FILE)
    File.open(CLIENT_CONFIG_FILE, "w") do |f|
      f.print(JSON.pretty_generate(chef_config))
    end
  end
else # no user-data ACK!
  chef_server_url        "http://chef.infinitemonkeys.info:4000"
  validation_client_name "chef-validator"
  node_name              OHAI_INFO[:ec2][:instance_id]
end

json_attribs CLIENT_CONFIG_FILE if File.exists?(CLIENT_CONFIG_FILE)
