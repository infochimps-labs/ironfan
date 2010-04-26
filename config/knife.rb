log_level                :info
log_location             STDERR
node_name                'knife_user'
validation_client_name   'chef-validator'
chef_server_url          'http://chef.infochimps.com:4000'
client_key               ENV['HOME']+'/.chef/knife_user.pem'
validation_key           ENV['HOME']+'/.chef/chef-validator.pem'
cache_options(  :path => ENV['HOME']+'/.chef/chef_checksums' )
cache_type               'BasicFile'
# Set the following to point to your hadoop_cluster_chef install
PATH_TO_COOKBOOK_REPOS = '~/ics/sysadmin'
cookbook_path            [ 'hadoop_cluster_chef/cookbooks', 'your_custom_chef/cookbooks', 'your_custom_chef/site-cookbooks', ].map{|path| File.expand_path(File.join(PATH_TO_COOKBOOK_REPOS, path)) }
