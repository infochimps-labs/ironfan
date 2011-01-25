current_dir   = File.dirname(__FILE__)

organization  = infochimps
username      = your_opscode_username

log_level                :info
log_location             STDOUT
node_name                username
client_key               "#{current_dir}/#{username}.pem"
validation_client_name   "#{organization}-validator"
validation_key           "#{current_dir}/#{organization}-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/#{organization}"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )

# Type in the full path to your cluster_chef installation
cluster_chef_path File.expand_path('~/ics/sysadmin/cluster_chef')
keypair_path      File.expand_path(current_dir+"/keypairs")

# Make sure knife can find all your junk
cookbook_path            ["#{cluster_chef_path}/cookbooks", "#{cluster_chef_path}/site-cookbooks",]

# Set your AWS access credentials
knife[:aws_access_key_id]      = "AWS_KEY"
knife[:aws_secret_access_key]  = "AWS_SECRET_ACCESS_KEY"

