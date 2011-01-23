current_dir   = File.dirname(__FILE__)
organization  = ENV['CHEF_ORGANIZATION']      || 'YOUR_ORGANIZATION'
username      = ENV['CHEF_USERNAME']          || 'YOUR_USERNAME'
cookbook_root = ENV['PATH_TO_COOKBOOK_REPOS'] || '~/ics/sysadmin'

log_level                :info
log_location             STDERR
node_name                username
validation_client_name   "#{organization}-validator"
client_key               "#{current_dir}/keypairs/#{username}-client_key.pem"
validation_key           "#{current_dir}/keypairs/#{organization}-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/#{organization}"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            [
  'cluster_chef/cookbooks', 'cluster_chef/site-cookbooks',
  ].map{|path| File.join(File.expand_path(cookbook_root), path) }

#
# Make sure to
#
# $ ssh-agent
#
# $ ssh-add ~/.ssh/ec2_ssh_key
# SSH_AUTH_SOCK=/tmp/ssh-RHHBa22270/agent.22270; export SSH_AUTH_SOCK;
# SSH_AGENT_PID=22271; export SSH_AGENT_PID;
# echo Agent pid 22271;

# EC2:
knife[:aws_access_key_id]      = "AWS_KEY"
knife[:aws_secret_access_key]  = "AWS_SECRET_ACCESS_KEY"

# Rackspace:
knife[:rackspace_api_key]      = "Your Rackspace API Key"
knife[:rackspace_api_username] = "Your Rackspace API username"

# Slicehost
knife[:slicehost_password]     = "Your Slicehost API password"

# # Terremark
# knife[:terremark_password]   = "Your Terremark Password"
# knife[:terremark_username]   = "Your Terremark Username"
# knife[:terremark_service]    = "Your Terremark Service name"
