log_level                :info
log_location             STDOUT
node_name                'knife_user'
client_key               ENV['HOME']+'/.chef/chef_keys/knife_user.pem'
validation_client_name   'chef-validator'
validation_key           ENV['HOME']+'/.chef/chef_keys/chef-validator.pem'
chef_server_url          'http://chef.infinitemonkeys.info:4000'
cache_type               'BasicFile'
cookbook_path            [ 'hadoop_cluster_chef/cookbooks', 'hadoop_cluster_chef/site-cookbooks', 'infochimps_chef/site-cookbooks', 'infochimps_chef/site-cookbooks', ].map{|path| File.join(ENV['HOME'], 'ics/sysadmin', path)}
cache_options( :path => File.join(ENV['HOME'], '.chef/chef_data/checksums') )
