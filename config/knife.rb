# -*- coding: utf-8 -*-
organization = ENV['CHEF_ORGANIZATION']
username     = ENV['CHEF_USER']

raise('please set the CHEF_ORGANIZATION and CHEF_USER variables to your chef server organization and username, resp.') unless organization && username

knife_dir    = File.dirname(__FILE__)
repo_dir     = File.expand_path("#{organization}-cookbooks", ENV['PATH_TO_COOKBOOK_REPOS'])

# The full path to your cluster_chef installation
cluster_chef_path        File.expand_path("#{repo_dir}/cluster_chef")
# The list of paths holding clusters
cluster_path             [ File.expand_path("#{repo_dir}/clusters") ]
# The directory holding your cloud keypairs -- be sure to `chmod og-rwx -R keypairs/`
keypair_path             File.expand_path("keypairs-#{organization}", knife_dir)

log_level                :info
log_location             STDOUT
node_name                username
client_key               File.expand_path("#{username}.pem", knife_dir)
validation_client_name   "#{organization}-validator"
validation_key           File.expand_path("#{organization}-validator.pem", knife_dir)
chef_server_url          "https://api.opscode.com/organizations/#{organization}"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )

cookbook_path            [
  "#{repo_dir}/cookbooks",
  "#{repo_dir}/site-cookbooks",
  "#{cluster_chef_path}/cookbooks",
]

# If you primarily use AWS cloud services:
knife[:ssh_address_attribute] = 'cloud.public_hostname'
knife[:ssh_user]              = 'ubuntu'

# Configure bootstrapping
knife[:bootstrap_runs_chef_client] = true
bootstrap_chef_version   "~> 0.10.4"

# Cloud access credentials
load "#{knife_dir}/#{organization}-credentials.rb" if File.exists?("#{knife_dir}/#{organization}-credentials.rb")
# Cloud resources -- Chef::Config[:ec2_image_info] and so forth
load "#{knife_dir}/#{organization}-cloud.rb"       if File.exists?("#{knife_dir}/#{organization}-cloud.rb")
# User-specific knife info
load "#{knife_dir}/knife-user-#{user}.rb"          if File.exists?("#{knife_dir}/knife-user-#{user}.rb")

#
# You can split the below into your knife-user-{user}.rb
#

# Configure cookbook templating
cookbook_copyright "Philip (flip) Kromer, infochimps.com"
cookbook_email     "coders@infochimps.com"
cookbook_license   "apachev2"
