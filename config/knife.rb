log_level                :info
log_location             STDERR
node_name                'knife_user'
validation_client_name   'chef-validator'
client_key               ENV['HOME']+'/.chef/keypairs/knife_user.pem'
validation_key           ENV['HOME']+'/.chef/keypairs/chef-validator.pem'
chef_server_url          'http://chef.infinitemonkeys.info:4000'
cache_type               'BasicFile'
PATH_TO_COOKBOOK_REPOS = File.join(ENV['HOME'], 'ics/sysadmin')
cookbook_path            [ 'hadoop_cluster_chef/cookbooks', 'hadoop_cluster_chef/site-cookbooks', 'infochimps_chef/cookbooks', 'infochimps_chef/site-cookbooks',
  ].map{|path| File.join(PATH_TO_COOKBOOK_REPOS, path) }
cache_options( :path => File.join(ENV['HOME'], '.chef/chef_checksums') )

