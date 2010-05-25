log_level                :info
log_location             STDERR
node_name                'knife_user'
validation_client_name   'chef-validator'
client_key               ENV['HOME']+'/.chef/keypairs/knife_user.pem'
validation_key           ENV['HOME']+'/.chef/keypairs/chef-validator.pem'
chef_server_url          'http://chef.infochimps.com:4000'
cache_type               'BasicFile'
CHEF_COOKBOOKS_ROOT = File.expand_path(ENV['CHEF_COOKBOOKS_ROOT'] || '~/ics/sysadmin')
cookbook_path            [ 'cluster_chef/cookbooks',
  ].map{|path| File.join(CHEF_COOKBOOKS_ROOT, path) }
cache_options( :path => File.expand_path('~/.chef/chef_checksums') )

