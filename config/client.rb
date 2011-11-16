require "ohai"
require "json"

#
# Load configuration
#

def merge_safely hsh
  hsh.merge!( yield ) rescue Mash.new
end

def create_file_if_empty(filename, str)
  unless File.exists?(filename)
    puts "Populating #{filename}" ;
    File.open(filename, "w", 0600){|f| f.puts(str) }
  end
end

def present?(config, key)
  not config[key].to_s.empty?
end

# Start with a set of defaults
chef_config = Mash.new

# Extract client configuration from EC2 user-data
OHAI_INFO = Ohai::System.new
OHAI_INFO.all_plugins
merge_safely(chef_config){ JSON.parse(OHAI_INFO[:ec2][:userdata]) }

#
# Configure chef run
#

log_level              :info
log_location           STDOUT
node_name              chef_config["node_name"]              if chef_config["node_name"]
chef_server_url        chef_config["chef_server"]            if chef_config["chef_server"]
validation_client_name chef_config["validation_client_name"] if chef_config["validation_client_name"]
validation_key         "/etc/chef/validation.pem"
client_key             "/etc/chef/client.pem"
node_attrs_file        "/etc/chef/first-boot.json"

# If the client file is missing, write the validation key out so chef-client can register
unless File.exists?(client_key)
  if    present?(chef_config, "client_key")     then create_file_if_empty(client_key,     chef_config["client_key"])
  elsif present?(chef_config, "validation_key") then create_file_if_empty(validation_key, chef_config["validation_key"])
  else  warn "Yikes -- I have no client key or validation key!!"
  end
end

reduced_chef_config = chef_config.reject{|k,v| k.to_s =~ /(_key|run_list)$/ }
unless File.exists?(node_attrs_file)
  create_file_if_empty(node_attrs_file, JSON.pretty_generate(reduced_chef_config))
end
json_attribs node_attrs_file

Chef::Log.debug(JSON.generate(chef_config))
Chef::Log.info("=> chef client #{node_name} on #{chef_server_url} in cluster +#{chef_config["cluster_name"]}+")
