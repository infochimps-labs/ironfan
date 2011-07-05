current_dir   = File.expand_path('~/.chef')
organization  = 'infochimps'
username      = 'mrflip'

cookbook_root = ENV['PATH_TO_COOKBOOK_REPOS'] || File.expand_path('~/ics/sysadmin')

cluster_chef_path       File.expand_path(cookbook_root+'/cluster_chef')
keypair_path            File.expand_path(current_dir+"/keypairs")
cookbook_path    [
  "cluster_chef/cookbooks",         "cluster_chef/site-cookbooks",
  ].map{|path| File.join(cookbook_root, path) }
cluster_path     [
  'cluster_chef/clusters',
  ].map{|path| File.join(cookbook_root, path) }

node_name                username
validation_client_name   "chef-validator"
validation_key           "#{keypair_path}/#{organization}-validator.pem"
client_key               "#{keypair_path}/#{username}-client_key.pem"
chef_server_url          "https://api.opscode.com/organizations/#{organization}"

load current_dir+"/#{organization}-awskeys.rb"
